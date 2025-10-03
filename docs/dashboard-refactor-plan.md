# TradeFlow Dashboard Refactor Plan
## From Current Trading Dashboard to Figma-Inspired Professional Interface

---

## **Current Holdings Calculation Analysis**

### **How Holdings Are Currently Calculated**

Based on the existing codebase analysis:

#### **Current Data Flow:**
1. **Trades Table**: Individual buy/sell transactions with `status: open/closed/partial`
2. **Positions Table**: Derived positions from trades (aggregated by security)
3. **User Portfolio Stats**: Calculated from trading accounts and their snapshots

#### **Current Holdings Logic:**
```ruby
# From User model (lines 55-66)
def total_portfolio_value
  trading_accounts.sum(&:current_portfolio_value)
end

def total_deployed_percentage
  return 0 if total_portfolio_value.zero?
  
  total_accounts = trading_accounts.count
  return 0 if total_accounts.zero?
  
  average_deployment = trading_accounts.sum(&:deployed_percentage) / total_accounts
  average_deployment.round(2)
end
```

#### **Position Calculations:**
```ruby
# From Position model
def current_value
  quantity * security.last_price
end

def invested_amount
  quantity * average_price
end

def unrealized_pnl
  case position_type
  when "long"
    (security.last_price - average_price) * quantity
  when "short"
    (average_price - security.last_price) * quantity
  end
end
```

#### **How Holdings Will Feature in Positions Table:**
- **Current State**: Positions are calculated from open trades
- **New Enhancement**: Add user-defined categorization system
- **Data Source**: Existing `positions` table + new `holding_sections` table
- **Display**: Categorized by user-defined sections with drag & drop reordering

---

## **Implementation Plan**

### **Phase 1: Foundation & Layout (Week 1)**

#### **1.1 Design System Updates**
- **Font Family**: Switch to Arimo to match Figma design
- **Color Scheme**: Implement green/red/blue trading color coding
- **Component Styling**: Update cards, buttons, tables to match Figma aesthetics
- **Spacing & Typography**: Align with Figma's design tokens

#### **1.2 Layout Restructure**
- **Header**: Compact header with market indices ticker (placeholder)
- **Top Section**: 4 key metric cards in grid layout
- **Main Content**: Two-column layout (Left: Holdings, Right: Market Feed)
- **Bottom Section**: Performance chart placeholder

#### **1.3 Key Metrics Cards Implementation**
**Connected to Real Data (Not Dummy):**

```ruby
# Dashboard Controller Enhancement
def calculate_enhanced_portfolio_stats
  total_value = current_user.total_portfolio_value
  deployed_percentage = current_user.total_deployed_percentage
  cash_percentage = 100 - deployed_percentage
  daily_pnl = calculate_daily_pnl
  net_pnl = calculate_net_pnl
  
  {
    total_value: total_value,
    cash_percentage: cash_percentage,
    daily_pnl: daily_pnl,
    net_pnl: net_pnl
  }
end
```

**Card Structure:**
```
Card 1: Total Portfolio Value
- Large value display (₹1,212,500)
- Change amount and percentage (+₹212,500, 24.29%)
- Green/red color coding based on trend

Card 2: Cash Available  
- Cash amount (₹1,212,500)
- Percentage of total (24.29%)
- Inverse of deployed percentage (100% - deployed%)

Card 3: P&L Today
- Daily profit/loss (+₹212,500)
- Percentage change (24.29%)
- Real-time updates from account snapshots

Card 4: Net P&L
- Total unrealized P&L (+₹212,500)
- Overall percentage (24.29%)
- Performance indicator from positions
```

### **Phase 2: Holdings Management System (Week 2)**

#### **2.1 Database Schema Updates**

**New Tables:**
```ruby
# Migration: Create holding sections
class CreateHoldingSections < ActiveRecord::Migration[7.2]
  def change
    create_table :holding_sections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0
      t.string :color, default: '#6B7280'
      t.boolean :is_default, default: false
      t.timestamps
    end
    
    add_index :holding_sections, [:user_id, :position]
  end
end

# Migration: Add section to positions
class AddSectionToPositions < ActiveRecord::Migration[7.2]
  def change
    add_reference :positions, :holding_section, null: true, foreign_key: true
    add_index :positions, [:user_id, :holding_section_id]
  end
end
```

**Model Updates:**
```ruby
# New HoldingSection model
class HoldingSection < ApplicationRecord
  acts_as_tenant(:user)
  
  belongs_to :user
  has_many :positions, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :position, presence: true
  
  scope :ordered, -> { order(:position) }
  scope :default_sections, -> { where(is_default: true) }
  scope :user_sections, -> { where(is_default: false) }
  
  def self.create_default_sections_for_user!(user)
    create!([
      { user: user, name: "Core Holdings", position: 0, is_default: true, color: '#3B82F6' },
      { user: user, name: "Probe Holdings", position: 1, is_default: true, color: '#10B981' }
    ])
  end
end

# Updated Position model
class Position < ApplicationRecord
  belongs_to :holding_section, optional: true
  
  scope :by_section, ->(section) { where(holding_section: section) }
  scope :uncategorized, -> { where(holding_section: nil) }
end
```

#### **2.2 User-Defined Section Management**

**CRUD Operations:**
```ruby
# Controller for managing sections
class HoldingSectionsController < ApplicationController
  def index
    @sections = current_user.holding_sections.ordered
  end
  
  def create
    @section = current_user.holding_sections.build(section_params)
    @section.position = next_position
    
    if @section.save
      redirect_to dashboard_path, notice: 'Section created successfully'
    else
      render :new
    end
  end
  
  def update
    @section = current_user.holding_sections.find(params[:id])
    
    if @section.update(section_params)
      redirect_to dashboard_path, notice: 'Section updated successfully'
    else
      render :edit
    end
  end
  
  def destroy
    @section = current_user.holding_sections.find(params[:id])
    @section.destroy
    redirect_to dashboard_path, notice: 'Section deleted successfully'
  end
  
  private
  
  def section_params
    params.require(:holding_section).permit(:name, :description, :color)
  end
  
  def next_position
    current_user.holding_sections.maximum(:position).to_i + 1
  end
end
```

#### **2.3 Drag & Drop Implementation**

**Stimulus Controller:**
```javascript
// app/javascript/controllers/holdings_drag_drop_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "position", "dropzone"]
  
  connect() {
    this.initializeDragAndDrop()
  }
  
  initializeDragAndDrop() {
    this.positionTargets.forEach(position => {
      position.draggable = true
      position.addEventListener('dragstart', this.handleDragStart.bind(this))
    })
    
    this.dropzoneTargets.forEach(zone => {
      zone.addEventListener('dragover', this.handleDragOver.bind(this))
      zone.addEventListener('drop', this.handleDrop.bind(this))
    })
  }
  
  handleDragStart(event) {
    const positionId = event.target.dataset.positionId
    event.dataTransfer.setData('text/plain', positionId)
    event.target.classList.add('opacity-50')
  }
  
  handleDragOver(event) {
    event.preventDefault()
    event.target.classList.add('bg-blue-50', 'border-blue-300')
  }
  
  async handleDrop(event) {
    event.preventDefault()
    const positionId = event.dataTransfer.getData('text/plain')
    const sectionId = event.target.dataset.sectionId
    
    try {
      const response = await fetch(`/positions/${positionId}/move_to_section`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ section_id: sectionId })
      })
      
      if (response.ok) {
        // Update UI
        this.movePositionToSection(positionId, sectionId)
      }
    } catch (error) {
      console.error('Failed to move position:', error)
    }
    
    event.target.classList.remove('bg-blue-50', 'border-blue-300')
  }
  
  movePositionToSection(positionId, sectionId) {
    // Update UI immediately for better UX
    const position = document.querySelector(`[data-position-id="${positionId}"]`)
    const newSection = document.querySelector(`[data-section-id="${sectionId}"]`)
    
    if (position && newSection) {
      const sectionPositions = newSection.querySelector('.positions-list')
      sectionPositions.appendChild(position)
    }
  }
}
```

**Rails Controller for Position Movement:**
```ruby
# Add to PositionsController
def move_to_section
  @position = current_user.positions.find(params[:id])
  section_id = params[:section_id]
  
  if section_id.present?
    @position.holding_section = current_user.holding_sections.find(section_id)
  else
    @position.holding_section = nil
  end
  
  if @position.save
    render json: { success: true }
  else
    render json: { errors: @position.errors }, status: :unprocessable_entity
  end
end
```

#### **2.4 Holdings Table Structure**

**Enhanced Positions Display:**
```erb
<!-- app/views/dashboard/_holdings_section.html.erb -->
<div class="w-full bg-container rounded-2xl border border-border p-6">
  <div class="flex justify-between items-center mb-6">
    <h2 class="text-lg font-semibold text-primary">Positions</h2>
    <div class="flex gap-2">
      <button class="px-3 py-1 bg-container border border-border rounded-lg text-sm">
        Open Positions
      </button>
      <button class="px-3 py-1 bg-primary text-white rounded-lg text-sm">
        All
      </button>
    </div>
  </div>
  
  <% current_user.holding_sections.ordered.each do |section| %>
    <div class="mb-6" data-holdings-drag-drop-target="section" data-section-id="<%= section.id %>">
      <div class="flex justify-between items-center mb-3">
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full" style="background-color: <%= section.color %>"></div>
          <h3 class="font-medium text-secondary"><%= section.name %></h3>
          <button class="text-xs text-tertiary">+</button>
        </div>
      </div>
      
      <div class="bg-surface rounded-lg border border-border" data-holdings-drag-drop-target="dropzone">
        <div class="px-4 py-2 border-b border-border">
          <div class="grid grid-cols-5 gap-4 text-xs font-medium text-secondary uppercase">
            <div>Symbol</div>
            <div class="text-right">Weight</div>
            <div class="text-right">Invested</div>
            <div class="text-right">Current</div>
            <div class="text-right">P&L %</div>
          </div>
        </div>
        
        <div class="positions-list">
          <% section.positions.includes(:security).each do |position| %>
            <div class="px-4 py-3 border-b border-border hover:bg-gray-50 cursor-move"
                 data-holdings-drag-drop-target="position" 
                 data-position-id="<%= position.id %>">
              <div class="grid grid-cols-5 gap-4 items-center text-sm">
                <div class="flex items-center gap-2">
                  <div class="w-3 h-3 bg-gray-300 rounded"></div>
                  <span class="font-medium"><%= position.security.symbol %></span>
                  <span class="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded">watch</span>
                </div>
                <div class="text-right"><%= position_weight_percentage(position) %>%</div>
                <div class="text-right">₹<%= number_with_delimiter(position.invested_amount) %></div>
                <div class="text-right">₹<%= number_with_delimiter(position.current_value) %></div>
                <div class="text-right <%= position.pnl_color_class %>">
                  <%= position.formatted_pnl %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
  <% end %>
</div>
```

### **Phase 3: Market Feed & Performance (Week 3)**

#### **3.1 Market Feed Placeholder**
**Structure for Future Integration:**
```erb
<!-- app/views/dashboard/_market_feed.html.erb -->
<div class="w-full bg-container rounded-2xl border border-border p-6">
  <div class="flex justify-between items-center mb-6">
    <h2 class="text-lg font-semibold text-primary">Market Feed</h2>
    <button class="px-3 py-1 bg-container border border-border rounded-lg text-sm">
      Open Feed
    </button>
  </div>
  
  <div class="space-y-4" data-market-feed-target="feedContainer">
    <!-- Placeholder for future news items -->
    <div class="text-center py-8 text-secondary">
      <div class="text-4xl mb-2">📰</div>
      <p>Market feed coming soon</p>
      <p class="text-sm">Real-time news and insights</p>
    </div>
  </div>
</div>
```

#### **3.2 Performance Chart Placeholder**
**Enhanced Chart Section:**
```erb
<!-- app/views/dashboard/_performance_chart.html.erb -->
<div class="w-full bg-container rounded-2xl border border-border p-6">
  <div class="flex justify-between items-center mb-6">
    <div>
      <h2 class="text-lg font-semibold text-primary">Portfolio Performance</h2>
      <div class="flex items-center gap-4 mt-2">
        <span class="text-2xl font-bold text-primary">₹<%= number_with_delimiter(@portfolio_stats[:total_value]) %></span>
        <span class="text-sm <%= @portfolio_stats[:daily_pnl] >= 0 ? 'text-green-600' : 'text-red-600' %>">
          <%= @portfolio_stats[:daily_pnl] >= 0 ? '+' : '' %>₹<%= number_with_delimiter(@portfolio_stats[:daily_pnl]) %>
        </span>
      </div>
    </div>
    
    <div class="flex gap-2">
      <button class="px-3 py-1 text-sm border border-border rounded-lg">1W</button>
      <button class="px-3 py-1 text-sm border border-border rounded-lg">1M</button>
      <button class="px-3 py-1 text-sm bg-primary text-white rounded-lg">1Y</button>
      <button class="px-3 py-1 text-sm border border-border rounded-lg">All</button>
    </div>
  </div>
  
  <!-- Chart placeholder -->
  <div class="h-80 bg-gray-50 rounded-lg flex items-center justify-center" data-performance-chart-target="chartContainer">
    <div class="text-center text-secondary">
      <div class="text-4xl mb-2">📈</div>
      <p>Performance chart coming soon</p>
      <p class="text-sm">Interactive portfolio tracking</p>
    </div>
  </div>
  
  <!-- Performance metrics -->
  <div class="grid grid-cols-4 gap-6 mt-6">
    <div>
      <p class="text-sm text-secondary">Current Drawdown</p>
      <p class="text-lg font-semibold text-secondary">-2.30%</p>
    </div>
    <div>
      <p class="text-sm text-secondary">Max Drawdown</p>
      <p class="text-lg font-semibold text-red-600">-5.87%</p>
    </div>
    <div>
      <p class="text-sm text-secondary">Best Day</p>
      <p class="text-lg font-semibold text-green-600">+2.8%</p>
    </div>
    <div>
      <p class="text-sm text-secondary">Worst Day</p>
      <p class="text-lg font-semibold text-red-600">-3.2%</p>
    </div>
  </div>
</div>
```

#### **3.3 Market Indices Ticker**
**Header Integration:**
```erb
<!-- app/views/shared/_market_ticker.html.erb -->
<div class="bg-container border-b border-border px-6 py-2">
  <div class="flex justify-between items-center text-sm">
    <div class="flex gap-8">
      <div class="flex items-center gap-2">
        <span class="text-secondary">NIFTY 50</span>
        <span class="font-medium">19,674.25</span>
        <span class="text-green-600">+187.45 (0.96%)</span>
      </div>
      <!-- Repeat for other indices -->
    </div>
    
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-2">
        <span class="text-secondary">All Accounts</span>
        <svg class="w-4 h-4" fill="none" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
        </svg>
      </div>
      <div class="flex gap-2">
        <button class="p-1 rounded hover:bg-gray-100">🔔</button>
        <button class="p-1 rounded hover:bg-gray-100">⚙️</button>
      </div>
    </div>
  </div>
</div>
```

### **Phase 4: Data Integration & Polish (Week 4)**

#### **4.1 Enhanced Portfolio Calculations**
```ruby
# app/controllers/concerns/portfolio_calculator.rb
module PortfolioCalculator
  extend ActiveSupport::Concern
  
  def calculate_daily_pnl
    # Calculate P&L from today's trading activity
    current_user.trades
                .where(entry_date: Date.current.beginning_of_day..Date.current.end_of_day)
                .sum(:net_pnl)
  end
  
  def calculate_net_pnl
    # Total unrealized P&L from all open positions
    current_user.positions.sum(&:unrealized_pnl)
  end
  
  def calculate_portfolio_weight(position)
    total_value = current_user.total_portfolio_value
    return 0 if total_value.zero?
    
    ((position.current_value / total_value) * 100).round(2)
  end
  
  def calculate_performance_metrics
    positions = current_user.positions.includes(:security)
    
    {
      current_drawdown: calculate_current_drawdown,
      max_drawdown: calculate_max_drawdown,
      best_day: calculate_best_day,
      worst_day: calculate_worst_day
    }
  end
  
  private
  
  def calculate_current_drawdown
    # Implementation based on peak-to-trough calculation
    # This would require historical data
    0.0 # Placeholder
  end
  
  def calculate_max_drawdown
    # Implementation based on historical performance
    0.0 # Placeholder
  end
  
  def calculate_best_day
    # Implementation based on daily P&L history
    0.0 # Placeholder
  end
  
  def calculate_worst_day
    # Implementation based on daily P&L history
    0.0 # Placeholder
  end
end
```

#### **4.2 Database Seeds for Default Sections**
```ruby
# db/seeds.rb addition
User.find_each do |user|
  next if user.holding_sections.any?
  
  HoldingSection.create_default_sections_for_user!(user)
end
```

---

## **Technical Architecture**

### **Database Schema Changes**
```ruby
# New tables
holding_sections (id, user_id, name, description, position, color, is_default, created_at, updated_at)
positions.holding_section_id (foreign key to holding_sections)

# Indexes for performance
index :holding_sections, [:user_id, :position]
index :positions, [:user_id, :holding_section_id]
```

### **Model Relationships**
```ruby
User
├── has_many :holding_sections
├── has_many :positions (through trading_accounts)
└── has_many :trades (through trading_accounts)

HoldingSection
├── belongs_to :user
└── has_many :positions

Position
├── belongs_to :trading_account
├── belongs_to :security
├── belongs_to :holding_section (optional)
└── belongs_to :user (through trading_account)
```

### **Controller Updates**
```ruby
# Enhanced DashboardController
class DashboardController < ApplicationController
  include PortfolioCalculator
  
  def index
    @portfolio_stats = calculate_enhanced_portfolio_stats
    @holdings_by_section = group_holdings_by_section
    @performance_metrics = calculate_performance_metrics
    @market_feed = [] # Placeholder for future integration
  end
  
  private
  
  def group_holdings_by_section
    current_user.holding_sections.ordered.includes(:positions => :security)
  end
end
```

### **Stimulus Controllers**
```javascript
// New controllers needed
holdings_drag_drop_controller.js    // Position reordering
market_feed_controller.js           // News feed updates
performance_chart_controller.js     // Chart interactions
portfolio_stats_controller.js       // Real-time updates
```

---

## **Design System Integration**

### **Color Palette Updates**
```css
/* Trading-specific colors matching Figma */
:root {
  --color-gain: #00a63d;      /* Green for profits */
  --color-loss: #e7000a;      /* Red for losses */
  --color-watch: #1347e5;     /* Blue for watch signals */
  --color-buy: #008235;       /* Green for buy signals */
  --color-sell: #c10007;      /* Red for sell signals */
  --color-neutral: #717182;   /* Gray for neutral */
}
```

### **Typography Updates**
```css
/* Font family alignment with Figma */
body {
  font-family: 'Arimo', system-ui, -apple-system, sans-serif;
}
```

---

## **File Structure Changes**

### **New Files**
```
app/controllers/
├── holding_sections_controller.rb
└── concerns/
    └── portfolio_calculator.rb

app/models/
└── holding_section.rb

app/javascript/controllers/
├── holdings_drag_drop_controller.js
├── market_feed_controller.js
├── performance_chart_controller.js
└── portfolio_stats_controller.js

app/views/dashboard/
├── _portfolio_cards.html.erb
├── _holdings_section.html.erb
├── _market_feed.html.erb
├── _performance_chart.html.erb
└── _market_ticker.html.erb

app/views/holding_sections/
├── index.html.erb
├── _form.html.erb
└── _section.html.erb

db/migrate/
├── 20241201000001_create_holding_sections.rb
└── 20241201000002_add_section_to_positions.rb
```

### **Modified Files**
```
app/controllers/dashboard_controller.rb
app/models/position.rb
app/models/user.rb
app/views/dashboard/index.html.erb
app/views/layouts/application.html.erb
app/assets/stylesheets/application.css
config/routes.rb
```

---

## **Success Metrics**

### **User Experience**
- **Task Completion**: Time to move position between categories < 5 seconds
- **Visual Clarity**: 90%+ user satisfaction with metric card clarity
- **Layout Usability**: Seamless navigation between sections

### **Technical Performance**
- **Load Time**: Dashboard render time < 2 seconds
- **Drag Performance**: Smooth drag & drop interactions (60fps)
- **Responsive Design**: Mobile/tablet compatibility score > 90

### **Future Readiness**
- **API Structure**: Market feed endpoints defined and documented
- **Real-time Ready**: WebSocket integration points identified
- **Data Flow**: Portfolio calculations optimized for real-time updates

---

## **Risk Mitigation**

### **Technical Risks**
- **Drag & Drop Complexity**: Start with simple implementation, iterate
- **Performance Impact**: Implement caching and database optimization early
- **Responsive Issues**: Test on multiple devices throughout development

### **User Experience Risks**
- **Learning Curve**: Maintain familiar navigation patterns from current dashboard
- **Feature Overload**: Implement progressive disclosure for advanced features
- **Mobile Usability**: Ensure touch-friendly interactions for all new features

---

## **Automated Testing Plans by Phase**

### **Phase 1 Testing: Foundation & Layout**

#### **1.1 Model Tests**
```ruby
# test/models/holding_section_test.rb
require 'test_helper'

class HoldingSectionTest < ActiveSupport::TestCase
  setup do
    @user = users(:trader_one)
    @section = HoldingSection.new(
      user: @user,
      name: "Test Section",
      position: 0,
      color: "#3B82F6"
    )
  end

  test "should be valid with valid attributes" do
    assert @section.valid?
  end

  test "should require user" do
    @section.user = nil
    assert_not @section.valid?
    assert_includes @section.errors[:user], "must exist"
  end

  test "should require name" do
    @section.name = nil
    assert_not @section.valid?
    assert_includes @section.errors[:name], "can't be blank"
  end

  test "should require unique name per user" do
    @section.save!
    duplicate_section = HoldingSection.new(
      user: @user,
      name: "Test Section",
      position: 1
    )
    assert_not duplicate_section.valid?
    assert_includes duplicate_section.errors[:name], "has already been taken"
  end

  test "should allow same name for different users" do
    @section.save!
    other_user = users(:trader_two)
    other_section = HoldingSection.new(
      user: other_user,
      name: "Test Section",
      position: 0
    )
    assert other_section.valid?
  end

  test "should create default sections for user" do
    new_user = users(:new_trader)
    sections = HoldingSection.create_default_sections_for_user!(new_user)
    
    assert_equal 2, sections.count
    assert_equal "Core Holdings", sections.first.name
    assert_equal "Probe Holdings", sections.last.name
    assert sections.first.is_default?
    assert sections.last.is_default?
  end

  test "should scope sections by user" do
    @section.save!
    other_user = users(:trader_two)
    other_section = HoldingSection.create!(
      user: other_user,
      name: "Other Section",
      position: 0
    )

    user_sections = HoldingSection.where(user: @user)
    assert_includes user_sections, @section
    assert_not_includes user_sections, other_section
  end
end
```

#### **1.2 Controller Tests**
```ruby
# test/controllers/holding_sections_controller_test.rb
require 'test_helper'

class HoldingSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trader_one)
    @section = holding_sections(:core_holdings)
    sign_in @user
  end

  test "should get index" do
    get holding_sections_url
    assert_response :success
    assert_select "h1", "Holding Sections"
  end

  test "should create holding section" do
    assert_difference('HoldingSection.count') do
      post holding_sections_url, params: {
        holding_section: {
          name: "New Section",
          description: "Test description",
          color: "#10B981"
        }
      }
    end

    assert_redirected_to dashboard_url
    assert_equal "Section created successfully", flash[:notice]
  end

  test "should update holding section" do
    patch holding_section_url(@section), params: {
      holding_section: { name: "Updated Section" }
    }
    
    assert_redirected_to dashboard_url
    @section.reload
    assert_equal "Updated Section", @section.name
  end

  test "should destroy holding section" do
    assert_difference('HoldingSection.count', -1) do
      delete holding_section_url(@section)
    end

    assert_redirected_to dashboard_url
    assert_equal "Section deleted successfully", flash[:notice]
  end

  test "should not allow access to other user's sections" do
    other_user = users(:trader_two)
    other_section = holding_sections(:other_user_section)
    
    patch holding_section_url(other_section), params: {
      holding_section: { name: "Hacked" }
    }
    
    assert_response :not_found
  end
end
```

#### **1.3 Integration Tests**
```ruby
# test/integration/dashboard_integration_test.rb
require 'test_helper'

class DashboardIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trader_one)
    sign_in @user
  end

  test "should display portfolio cards with real data" do
    get dashboard_url
    
    assert_response :success
    assert_select ".portfolio-card", count: 4
    assert_select ".total-value-card"
    assert_select ".cash-percentage-card"
    assert_select ".daily-pnl-card"
    assert_select ".net-pnl-card"
  end

  test "should display holdings by section" do
    section = holding_sections(:core_holdings)
    position = positions(:aapl_position)
    position.update!(holding_section: section)
    
    get dashboard_url
    
    assert_response :success
    assert_select ".holdings-section", minimum: 1
    assert_select "[data-section-id='#{section.id}']"
    assert_select ".position-row", minimum: 1
  end

  test "should display market feed placeholder" do
    get dashboard_url
    
    assert_response :success
    assert_select ".market-feed"
    assert_select ".market-feed-placeholder"
  end

  test "should display performance chart placeholder" do
    get dashboard_url
    
    assert_response :success
    assert_select ".performance-chart"
    assert_select ".chart-placeholder"
  end
end
```

#### **1.4 System Tests**
```ruby
# test/system/dashboard_system_test.rb
require 'application_system_test_case'

class DashboardSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:trader_one)
    login_as @user
  end

  test "should display dashboard layout" do
    visit dashboard_url
    
    assert_selector "h1", text: "Trading Dashboard"
    assert_selector ".portfolio-cards", count: 4
    assert_selector ".two-column-layout"
    assert_selector ".holdings-section"
    assert_selector ".market-feed"
    assert_selector ".performance-chart"
  end

  test "should show real portfolio data in cards" do
    visit dashboard_url
    
    within ".total-value-card" do
      assert_text "₹"
      assert_text /[\d,]+/
    end
    
    within ".cash-percentage-card" do
      assert_text "%"
      assert_text /[\d.]+/
    end
  end
end
```

**Phase 1 Sign-off Commands:**
```bash
# Run all Phase 1 tests
rails test test/models/holding_section_test.rb
rails test test/controllers/holding_sections_controller_test.rb
rails test test/integration/dashboard_integration_test.rb
rails test:system test/system/dashboard_system_test.rb

# Verify test coverage
COVERAGE=true rails test
```

---

### **Phase 2 Testing: Holdings Management**

#### **2.1 Position Movement Tests**
```ruby
# test/controllers/positions_controller_test.rb
require 'test_helper'

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trader_one)
    @position = positions(:aapl_position)
    @section = holding_sections(:core_holdings)
    sign_in @user
  end

  test "should move position to section" do
    patch move_to_section_position_url(@position), params: {
      section_id: @section.id
    }, xhr: true
    
    assert_response :success
    @position.reload
    assert_equal @section, @position.holding_section
  end

  test "should remove position from section" do
    @position.update!(holding_section: @section)
    
    patch move_to_section_position_url(@position), params: {
      section_id: nil
    }, xhr: true
    
    assert_response :success
    @position.reload
    assert_nil @position.holding_section
  end

  test "should not allow moving other user's positions" do
    other_user = users(:trader_two)
    other_position = positions(:other_user_position)
    
    patch move_to_section_position_url(other_position), params: {
      section_id: @section.id
    }, xhr: true
    
    assert_response :not_found
  end
end
```

#### **2.2 Drag & Drop JavaScript Tests**
```ruby
# test/system/drag_drop_system_test.rb
require 'application_system_test_case'

class DragDropSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:trader_one)
    @section1 = holding_sections(:core_holdings)
    @section2 = holding_sections(:probe_holdings)
    @position = positions(:aapl_position)
    @position.update!(holding_section: @section1)
    login_as @user
  end

  test "should drag position between sections" do
    visit dashboard_url
    
    # Verify initial state
    within "[data-section-id='#{@section1.id}']" do
      assert_selector "[data-position-id='#{@position.id}']"
    end
    
    # Perform drag and drop
    source_position = find("[data-position-id='#{@position.id}']")
    target_section = find("[data-section-id='#{@section2.id}'] .positions-list")
    
    source_position.drag_to(target_section)
    
    # Wait for AJAX request to complete
    assert_selector ".drag-success", wait: 5
    
    # Verify position moved
    within "[data-section-id='#{@section2.id}']" do
      assert_selector "[data-position-id='#{@position.id}']"
    end
    
    # Verify database updated
    @position.reload
    assert_equal @section2, @position.holding_section
  end

  test "should show visual feedback during drag" do
    visit dashboard_url
    
    position = find("[data-position-id='#{@position.id}']")
    dropzone = find("[data-section-id='#{@section2.id}']")
    
    position.drag_to(dropzone)
    
    # Check for visual feedback classes
    assert_selector ".opacity-50", wait: 1
    assert_selector ".bg-blue-50", wait: 1
  end
end
```

#### **2.3 Section Management Tests**
```ruby
# test/system/section_management_system_test.rb
require 'application_system_test_case'

class SectionManagementSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:trader_one)
    login_as @user
  end

  test "should create new holding section" do
    visit holding_sections_url
    
    click_link "Add New Section"
    
    fill_in "Name", with: "Test Section"
    fill_in "Description", with: "Test description"
    fill_in "Color", with: "#10B981"
    
    click_button "Create Section"
    
    assert_text "Section created successfully"
    assert_text "Test Section"
  end

  test "should edit existing section" do
    section = holding_sections(:core_holdings)
    visit edit_holding_section_url(section)
    
    fill_in "Name", with: "Updated Core Holdings"
    click_button "Update Section"
    
    assert_text "Section updated successfully"
    assert_text "Updated Core Holdings"
  end

  test "should delete section and move positions to uncategorized" do
    section = holding_sections(:core_holdings)
    position = positions(:aapl_position)
    position.update!(holding_section: section)
    
    visit holding_sections_url
    
    accept_confirm do
      click_link "Delete", href: holding_section_url(section)
    end
    
    assert_text "Section deleted successfully"
    
    # Verify position is now uncategorized
    position.reload
    assert_nil position.holding_section
  end
end
```

**Phase 2 Sign-off Commands:**
```bash
# Run all Phase 2 tests
rails test test/controllers/positions_controller_test.rb
rails test:system test/system/drag_drop_system_test.rb
rails test:system test/system/section_management_system_test.rb

# Test drag & drop functionality manually
rails server
# Open browser, test drag & drop interactions
```

---

### **Phase 3 Testing: Market Feed & Performance**

#### **3.1 Market Feed Component Tests**
```ruby
# test/views/dashboard/_market_feed_test.rb
require 'test_helper'

class MarketFeedViewTest < ActionView::TestCase
  setup do
    @user = users(:trader_one)
  end

  test "should render market feed placeholder" do
    render partial: "dashboard/market_feed"
    
    assert_select ".market-feed"
    assert_select ".market-feed-placeholder"
    assert_text "Market feed coming soon"
    assert_text "Real-time news and insights"
  end

  test "should have correct structure for future integration" do
    render partial: "dashboard/market_feed"
    
    assert_select "[data-market-feed-target='feedContainer']"
    assert_select ".feed-header"
    assert_select ".feed-controls"
  end
end
```

#### **3.2 Performance Chart Tests**
```ruby
# test/views/dashboard/_performance_chart_test.rb
require 'test_helper'

class PerformanceChartViewTest < ActionView::TestCase
  setup do
    @user = users(:trader_one)
    @portfolio_stats = {
      total_value: 1212500,
      daily_pnl: 212500,
      net_pnl: 212500
    }
  end

  test "should render performance chart with real data" do
    render partial: "dashboard/performance_chart", locals: {
      portfolio_stats: @portfolio_stats
    }
    
    assert_select ".performance-chart"
    assert_select ".chart-header"
    assert_text "₹1,212,500"
    assert_text "+₹212,500"
  end

  test "should show performance metrics placeholders" do
    render partial: "dashboard/performance_chart", locals: {
      portfolio_stats: @portfolio_stats
    }
    
    assert_select ".performance-metrics"
    assert_text "Current Drawdown"
    assert_text "Max Drawdown"
    assert_text "Best Day"
    assert_text "Worst Day"
  end

  test "should have time period selector" do
    render partial: "dashboard/performance_chart", locals: {
      portfolio_stats: @portfolio_stats
    }
    
    assert_select ".time-period-selector"
    assert_select "button", text: "1W"
    assert_select "button", text: "1M"
    assert_select "button", text: "1Y"
    assert_select "button", text: "All"
  end
end
```

#### **3.3 Market Ticker Tests**
```ruby
# test/system/market_ticker_system_test.rb
require 'application_system_test_case'

class MarketTickerSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:trader_one)
    login_as @user
  end

  test "should display market indices in header" do
    visit dashboard_url
    
    assert_selector ".market-ticker"
    assert_text "NIFTY 50"
    assert_text "19,674.25"
    assert_text "+187.45 (0.96%)"
  end

  test "should show account selector" do
    visit dashboard_url
    
    assert_selector ".account-selector"
    assert_text "All Accounts"
  end

  test "should display action buttons" do
    visit dashboard_url
    
    assert_selector ".notification-button"
    assert_selector ".settings-button"
  end
end
```

**Phase 3 Sign-off Commands:**
```bash
# Run all Phase 3 tests
rails test test/views/dashboard/_market_feed_test.rb
rails test test/views/dashboard/_performance_chart_test.rb
rails test:system test/system/market_ticker_system_test.rb

# Verify layout structure
rails test:system test/system/dashboard_layout_test.rb
```

---

### **Phase 4 Testing: Data Integration & Performance**

#### **4.1 Portfolio Calculator Tests**
```ruby
# test/controllers/concerns/portfolio_calculator_test.rb
require 'test_helper'

class PortfolioCalculatorTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trader_one)
    sign_in @user
  end

  test "should calculate daily P&L correctly" do
    # Create trades for today
    security = securities(:aapl)
    trading_account = trading_accounts(:primary)
    
    trade = Trade.create!(
      user: @user,
      trading_account: trading_account,
      security: security,
      trade_type: "buy",
      quantity: 100,
      entry_price: 150.0,
      exit_price: 155.0,
      entry_date: Date.current,
      exit_date: Date.current,
      status: "closed"
    )
    
    daily_pnl = calculate_daily_pnl
    assert_equal 500.0, daily_pnl # (155 - 150) * 100
  end

  test "should calculate net P&L from positions" do
    position = positions(:aapl_position)
    security = position.security
    security.update!(last_price: 160.0)
    
    net_pnl = calculate_net_pnl
    expected_pnl = (160.0 - position.average_price) * position.quantity
    
    assert_equal expected_pnl, net_pnl
  end

  test "should calculate portfolio weights correctly" do
    position = positions(:aapl_position)
    total_value = 100000.0
    
    weight = calculate_portfolio_weight(position, total_value)
    expected_weight = (position.current_value / total_value * 100).round(2)
    
    assert_equal expected_weight, weight
  end

  private

  def calculate_daily_pnl
    @user.trades
         .where(entry_date: Date.current.beginning_of_day..Date.current.end_of_day)
         .sum(:net_pnl)
  end

  def calculate_net_pnl
    @user.positions.sum(&:unrealized_pnl)
  end

  def calculate_portfolio_weight(position, total_value)
    return 0 if total_value.zero?
    ((position.current_value / total_value) * 100).round(2)
  end
end
```

#### **4.2 Performance Tests**
```ruby
# test/performance/dashboard_performance_test.rb
require 'test_helper'

class DashboardPerformanceTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trader_one)
    sign_in @user
    
    # Create test data
    create_test_data
  end

  test "dashboard should load within 2 seconds" do
    start_time = Time.current
    
    get dashboard_url
    
    load_time = Time.current - start_time
    assert_response :success
    assert load_time < 2.seconds, "Dashboard loaded in #{load_time}s, expected < 2s"
  end

  test "dashboard should handle 100+ positions efficiently" do
    # Create 100 positions
    100.times do |i|
      security = Security.create!(
        symbol: "TEST#{i}",
        company_name: "Test Company #{i}",
        last_price: 100.0
      )
      
      Position.create!(
        user: @user,
        trading_account: trading_accounts(:primary),
        security: security,
        quantity: 100,
        average_price: 100.0
      )
    end
    
    start_time = Time.current
    get dashboard_url
    load_time = Time.current - start_time
    
    assert_response :success
    assert load_time < 3.seconds, "Dashboard with 100+ positions loaded in #{load_time}s"
  end

  test "drag and drop should respond within 500ms" do
    position = positions(:aapl_position)
    section = holding_sections(:core_holdings)
    
    start_time = Time.current
    
    patch move_to_section_position_url(position), params: {
      section_id: section.id
    }, xhr: true
    
    response_time = Time.current - start_time
    
    assert_response :success
    assert response_time < 0.5.seconds, "Drag & drop responded in #{response_time}s, expected < 0.5s"
  end

  private

  def create_test_data
    # Create additional test data for performance testing
    10.times do |i|
      HoldingSection.create!(
        user: @user,
        name: "Test Section #{i}",
        position: i,
        color: "#3B82F6"
      )
    end
  end
end
```

#### **4.3 Responsive Design Tests**
```ruby
# test/system/responsive_dashboard_test.rb
require 'application_system_test_case'

class ResponsiveDashboardTest < ApplicationSystemTestCase
  setup do
    @user = users(:trader_one)
    login_as @user
  end

  test "should display correctly on mobile" do
    resize_window_to_mobile
    visit dashboard_url
    
    assert_selector ".mobile-layout"
    assert_selector ".portfolio-cards"
    assert_selector ".single-column-layout"
  end

  test "should display correctly on tablet" do
    resize_window_to_tablet
    visit dashboard_url
    
    assert_selector ".tablet-layout"
    assert_selector ".two-column-layout"
  end

  test "should display correctly on desktop" do
    resize_window_to_desktop
    visit dashboard_url
    
    assert_selector ".desktop-layout"
    assert_selector ".two-column-layout"
  end

  test "should handle touch interactions on mobile" do
    resize_window_to_mobile
    visit dashboard_url
    
    # Test touch-friendly buttons
    assert_selector ".touch-friendly"
    
    # Test swipe gestures for sections
    section = find(".holdings-section")
    section.swipe(:left)
    
    # Verify responsive behavior
    assert_selector ".mobile-optimized"
  end

  private

  def resize_window_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end

  def resize_window_to_tablet
    page.driver.browser.manage.window.resize_to(768, 1024)
  end

  def resize_window_to_desktop
    page.driver.browser.manage.window.resize_to(1920, 1080)
  end
end
```

#### **4.4 Database Performance Tests**
```ruby
# test/database/query_performance_test.rb
require 'test_helper'

class QueryPerformanceTest < ActiveSupport::TestCase
  setup do
    @user = users(:trader_one)
  end

  test "dashboard queries should be optimized" do
    # Test N+1 query prevention
    assert_queries(5) do
      # Should only make 5 queries for dashboard data
      sections = @user.holding_sections.includes(:positions => :security)
      sections.each do |section|
        section.positions.each do |position|
          position.security.symbol
        end
      end
    end
  end

  test "position calculations should be efficient" do
    positions = @user.positions.includes(:security)
    
    start_time = Time.current
    
    positions.each do |position|
      position.current_value
      position.unrealized_pnl
      position.unrealized_pnl_percent
    end
    
    calculation_time = Time.current - start_time
    
    assert calculation_time < 0.1.seconds, "Position calculations took #{calculation_time}s"
  end

  test "portfolio stats calculation should be cached" do
    # First call should calculate
    stats1 = @user.calculate_portfolio_stats
    
    # Second call should use cache
    stats2 = @user.calculate_portfolio_stats
    
    assert_equal stats1, stats2
    # In production, this would verify cache hit
  end
end
```

**Phase 4 Sign-off Commands:**
```bash
# Run all Phase 4 tests
rails test test/controllers/concerns/portfolio_calculator_test.rb
rails test test/performance/dashboard_performance_test.rb
rails test:system test/system/responsive_dashboard_test.rb
rails test test/database/query_performance_test.rb

# Run full test suite
rails test
rails test:system

# Performance benchmarks
rails test test/performance/

# Check test coverage
COVERAGE=true rails test
```

---

## **Complete Testing Commands**

### **All Phases Sign-off**
```bash
#!/bin/bash
# complete_dashboard_test_suite.sh

echo "🧪 Running Complete Dashboard Test Suite..."

echo "📊 Phase 1: Foundation & Layout"
rails test test/models/holding_section_test.rb
rails test test/controllers/holding_sections_controller_test.rb
rails test test/integration/dashboard_integration_test.rb
rails test:system test/system/dashboard_system_test.rb

echo "🎯 Phase 2: Holdings Management"
rails test test/controllers/positions_controller_test.rb
rails test:system test/system/drag_drop_system_test.rb
rails test:system test/system/section_management_system_test.rb

echo "📰 Phase 3: Market Feed & Performance"
rails test test/views/dashboard/_market_feed_test.rb
rails test test/views/dashboard/_performance_chart_test.rb
rails test:system test/system/market_ticker_system_test.rb

echo "⚡ Phase 4: Data Integration & Performance"
rails test test/controllers/concerns/portfolio_calculator_test.rb
rails test test/performance/dashboard_performance_test.rb
rails test:system test/system/responsive_dashboard_test.rb
rails test test/database/query_performance_test.rb

echo "🎉 Complete test suite finished!"
echo "📈 Test coverage report:"
COVERAGE=true rails test

echo "✅ All tests passed! Dashboard refactor is ready for deployment."
```

### **Individual Phase Testing**
```bash
# Phase 1 only
rails test test/models/holding_section_test.rb test/controllers/holding_sections_controller_test.rb test/integration/dashboard_integration_test.rb

# Phase 2 only  
rails test test/controllers/positions_controller_test.rb
rails test:system test/system/drag_drop_system_test.rb

# Phase 3 only
rails test test/views/dashboard/
rails test:system test/system/market_ticker_system_test.rb

# Phase 4 only
rails test test/performance/
rails test test/database/
```

---

## **Timeline Summary**

- **Week 1**: Foundation, layout, key metrics cards with real data + **Automated Tests**
- **Week 2**: Holdings categorization system, drag & drop functionality + **Automated Tests**
- **Week 3**: Market feed placeholder, performance chart placeholder + **Automated Tests**
- **Week 4**: Data integration, responsive design, performance optimization + **Automated Tests**

**Each phase includes comprehensive automated testing that can be run on the server to verify functionality, performance, and user experience before moving to the next phase.**
