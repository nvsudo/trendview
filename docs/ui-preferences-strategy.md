# UI Preferences Strategy - TradeFlow

## Overview

As TradeFlow grows, users will want to customize many aspects of the interface:
- Table column visibility (positions, trades, watchlist)
- Chart preferences (timeframe defaults, indicators)
- Dashboard layout (widget order, sizes)
- Display formats (number formats, date formats, timezone)
- Theme preferences (colors, fonts, density)

**Goal:** Create a flexible, extensible system that handles ALL UI preferences, not just position table columns.

---

## Account Size Calculation (Dashboard First Card)

### What It Should Be:
**Account Size = Sum of all open positions' current value + Cash balance**

This represents the total capital in the account (both deployed and available).

### Current Implementation (NEEDS UPDATE):
```ruby
# User model (app/models/user.rb:59-61)
def total_portfolio_value  # ← Rename to total_account_size
  trading_accounts.sum(&:current_portfolio_value)
end

# TradingAccount model (app/models/trading_account.rb:43-45)
def current_portfolio_value  # ← Rename to account_size
  account_snapshots.recent.first&.total_value || 0
end
```

**Current Issues:**
- Uses `total_value` from snapshots (may be stale)
- Doesn't directly calculate from live positions + cash
- Name is confusing ("portfolio value" vs. "account size")

### Correct Calculation (To Implement):
```ruby
# User model - rename and fix calculation
def total_account_size
  trading_accounts.sum(&:account_size)
end

def total_cash_balance
  trading_accounts.sum(&:cash_balance)
end

# TradingAccount model - calculate from positions + cash
def account_size
  open_positions_value + cash_balance
end

def open_positions_value
  positions.active.sum(&:current_value)
end

def cash_balance
  account_snapshots.recent.first&.cash_balance || 0
end
```

### Calculation Flow:
1. **User has multiple trading accounts** (personal, aggressive, family, etc.)
2. **Each account calculates:**
   - Open positions value = Sum of (quantity × last_price) for all active positions
   - Cash balance = From latest snapshot
   - Account size = Open positions value + Cash balance
3. **Total account size** = Sum of account_size from all accounts
4. **Total cash** = Sum of cash_balance from all accounts

### Example:
```
User "Nikunj" has 3 accounts:

Personal Account:
  - Open Positions: ₹450,000 (AAPL: ₹200k, MSFT: ₹150k, GOOGL: ₹100k)
  - Cash Balance: ₹50,000
  - Account Size: ₹500,000

Aggressive Account:
  - Open Positions: ₹250,000 (NVDA: ₹150k, TSLA: ₹100k)
  - Cash Balance: ₹50,000
  - Account Size: ₹300,000

Family Account:
  - Open Positions: ₹150,000 (Mutual funds)
  - Cash Balance: ₹50,000
  - Account Size: ₹200,000

Total Account Size = ₹500,000 + ₹300,000 + ₹200,000 = ₹1,000,000
Total Cash = ₹50,000 + ₹50,000 + ₹50,000 = ₹150,000
```

### Dashboard Cards Relationship:
1. **Account Size** (Card 1): Open Positions + Cash = ₹1,000,000
2. **Cash** (Card 2): Cash only = ₹150,000 **(subset of account size)**
3. **P&L Today** (Card 3): Day's profit/loss
4. **Net P&L** (Card 4): Total unrealized P&L

**Cash is a direct subset of Account Size** - it shows the available dry powder from the total capital.

### Data Sources:
- **Positions:** `positions.active.sum(&:current_value)`
  - Uses: `quantity × security.last_price`
- **Cash:** `account_snapshots.recent.first.cash_balance`
  - Fallback: 0 if no snapshots

### Implementation Updates Needed:

#### 1. User Model Changes:
```ruby
# app/models/user.rb
# Rename method
def total_account_size  # was: total_portfolio_value
  trading_accounts.sum(&:account_size)
end

# Add cash total method
def total_cash_balance
  trading_accounts.sum(&:cash_balance)
end
```

#### 2. TradingAccount Model Changes:
```ruby
# app/models/trading_account.rb
# Rename and recalculate
def account_size  # was: current_portfolio_value
  open_positions_value + cash_balance
end

def open_positions_value
  positions.active.sum(&:current_value)
end

def cash_balance
  account_snapshots.recent.first&.cash_balance || 0
end
```

#### 3. Dashboard Controller Changes:
```ruby
# app/controllers/dashboard_controller.rb
def calculate_enhanced_portfolio_stats
  total_account_size = current_user.total_account_size
  total_cash = current_user.total_cash_balance
  deployed_percentage = current_user.total_deployed_percentage
  daily_pnl = calculate_daily_pnl
  net_pnl = calculate_net_pnl

  {
    total_account_size: total_account_size,  # Renamed from total_value
    total_cash: total_cash,                   # New field
    cash_percentage: total_account_size.zero? ? 0 : (total_cash / total_account_size * 100).round(2),
    daily_pnl: daily_pnl,
    net_pnl: net_pnl,
    deployed_percentage: deployed_percentage
  }
end
```

#### 4. View Changes:
```erb
<!-- app/views/dashboard/index.html.erb -->

<!-- Card 1: Account Size (renamed from Total Value) -->
<div class="bg-container rounded-2xl border border-border p-6">
  <div class="text-sm text-secondary mb-1">Account Size</div>
  <div class="text-3xl font-semibold text-primary mb-2">
    ₹<%= number_with_delimiter(@portfolio_stats[:total_account_size]) %>
  </div>
  <div class="text-sm <%= @portfolio_stats[:daily_pnl] >= 0 ? 'text-green-600' : 'text-red-600' %>">
    <%= @portfolio_stats[:daily_pnl] >= 0 ? '+' : '' %>₹<%= number_with_delimiter(@portfolio_stats[:daily_pnl]) %>
    (<%= format_percentage_change(@portfolio_stats[:daily_pnl], @portfolio_stats[:total_account_size]) %>)
  </div>
</div>

<!-- Card 2: Cash (subset of Account Size) -->
<div class="bg-container rounded-2xl border border-border p-6">
  <div class="text-sm text-secondary mb-1">Cash</div>
  <div class="text-3xl font-semibold text-primary mb-2">
    ₹<%= number_with_delimiter(@portfolio_stats[:total_cash]) %>
  </div>
  <div class="text-sm text-secondary">
    <%= @portfolio_stats[:cash_percentage].round(2) %>% of account
  </div>
</div>
```

---

## UI Preferences System Design

### Architecture: Single Table with JSONB

**Why JSONB?**
- PostgreSQL's JSONB is perfect for schema-less preferences
- Query by key, update nested values, add new preferences without migrations
- Indexes on JSONB keys for performance
- Validates JSON structure at application level

### Database Schema

```sql
create_table "user_ui_preferences", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.string "preference_category", null: false  -- e.g., "dashboard", "positions_table", "charts"
  t.string "preference_key", null: false       -- e.g., "columns", "layout", "theme"
  t.jsonb "preference_value", default: {}, null: false
  t.text "description"                         -- Human-readable description
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["user_id", "preference_category", "preference_key"],
    name: "index_ui_prefs_unique",
    unique: true
  t.index ["preference_value"], using: :gin  -- For JSONB queries
end
```

**Key Design Decisions:**
- `preference_category` groups related preferences (e.g., all dashboard prefs)
- `preference_key` identifies specific setting within category
- `preference_value` stores actual settings as JSONB
- Unique index prevents duplicate preferences
- GIN index enables fast JSONB queries

---

## Preference Categories & Examples

### 1. **Position Table Columns** (Immediate Need)

**Category:** `positions_table`
**Key:** `columns`

**Value Structure:**
```json
{
  "symbol": { "visible": true, "order": 1, "width": 120 },
  "weight_percent": { "visible": true, "order": 2, "width": 80 },
  "quantity": { "visible": true, "order": 3, "width": 80 },
  "ltp": { "visible": true, "order": 4, "width": 100 },
  "invested": { "visible": false, "order": 5, "width": 100 },
  "current_value": { "visible": false, "order": 6, "width": 100 },
  "pnl_amount": { "visible": true, "order": 7, "width": 100 },
  "pnl_percent": { "visible": true, "order": 8, "width": 80 },
  "sentiment_tag": { "visible": false, "order": 9, "width": 80 }
}
```

**Default When Not Set:**
```ruby
DEFAULT_POSITION_COLUMNS = {
  symbol: { visible: true, order: 1, width: 120 },
  quantity: { visible: true, order: 2, width: 80 },
  ltp: { visible: true, order: 3, width: 100 },
  pnl_amount: { visible: true, order: 4, width: 100 },
  pnl_percent: { visible: true, order: 5, width: 80 }
}
```

---

### 2. **Dashboard Layout** (Future)

**Category:** `dashboard`
**Key:** `layout`

**Value Structure:**
```json
{
  "widget_order": ["stats_cards", "positions", "market_feed", "performance"],
  "stats_cards": {
    "visible": ["total_value", "cash", "pnl_today", "net_pnl"],
    "layout": "grid"  // or "row"
  },
  "positions": {
    "default_view": "sections",  // or "flat_list"
    "default_expanded": true
  },
  "market_feed": {
    "default_tab": "live",  // or "news"
    "items_per_page": 10
  }
}
```

---

### 3. **Number & Date Formatting** (Future)

**Category:** `display`
**Key:** `formats`

**Value Structure:**
```json
{
  "number_format": "indian",  // "indian" = 2,50,000 | "international" = 250,000
  "currency_symbol": "₹",
  "date_format": "dd/mm/yyyy",  // or "mm/dd/yyyy" or "yyyy-mm-dd"
  "time_format": "24h",  // or "12h"
  "timezone": "Asia/Kolkata",
  "decimal_places": {
    "currency": 2,
    "percentage": 2,
    "weight": 1
  }
}
```

---

### 4. **Chart Preferences** (Future)

**Category:** `charts`
**Key:** `defaults`

**Value Structure:**
```json
{
  "default_timeframe": "1M",  // 1D, 1W, 1M, 1Y, ALL
  "chart_type": "candlestick",  // or "line", "area"
  "indicators": ["SMA_50", "SMA_200", "RSI"],
  "colors": {
    "bullish": "#00A63E",
    "bearish": "#EC2222"
  }
}
```

---

### 5. **Table Preferences** (Extensible Pattern)

**Category:** `trades_table`
**Key:** `columns`

**Value Structure:**
```json
{
  "security": { "visible": true, "order": 1 },
  "entry_date": { "visible": true, "order": 2 },
  "exit_date": { "visible": true, "order": 3 },
  "quantity": { "visible": true, "order": 4 },
  "entry_price": { "visible": true, "order": 5 },
  "exit_price": { "visible": false, "order": 6 },
  "pnl": { "visible": true, "order": 7 },
  "strategy": { "visible": false, "order": 8 }
}
```

**Pattern Reuse:** Same structure for any table (watchlist, analytics, etc.)

---

## Model Implementation

### UserUiPreference Model

```ruby
class UserUiPreference < ApplicationRecord
  belongs_to :user

  validates :preference_category, presence: true
  validates :preference_key, presence: true
  validates :preference_value, presence: true
  validates :preference_key, uniqueness: { scope: [:user_id, :preference_category] }

  # Scopes for common queries
  scope :for_category, ->(category) { where(preference_category: category) }
  scope :for_key, ->(key) { where(preference_key: key) }

  # Class methods for easy access
  def self.get(user, category, key, default = {})
    pref = user.ui_preferences
               .for_category(category)
               .for_key(key)
               .first

    pref&.preference_value || default
  end

  def self.set(user, category, key, value, description = nil)
    pref = user.ui_preferences
               .find_or_initialize_by(
                 preference_category: category,
                 preference_key: key
               )

    pref.preference_value = value
    pref.description = description if description
    pref.save!
    pref
  end

  def self.update_nested(user, category, key, path, value)
    pref = get_record(user, category, key)
    current_value = pref&.preference_value || {}

    # Update nested JSONB value (e.g., columns.symbol.visible = true)
    keys = path.split('.')
    nested = current_value
    keys[0..-2].each { |k| nested = nested[k] ||= {} }
    nested[keys.last] = value

    set(user, category, key, current_value)
  end

  private

  def self.get_record(user, category, key)
    user.ui_preferences
        .for_category(category)
        .for_key(key)
        .first
  end
end
```

### User Model Association

```ruby
class User < ApplicationRecord
  has_many :ui_preferences,
           class_name: 'UserUiPreference',
           dependent: :destroy

  # Convenience methods
  def get_preference(category, key, default = {})
    UserUiPreference.get(self, category, key, default)
  end

  def set_preference(category, key, value)
    UserUiPreference.set(self, category, key, value)
  end

  # Specific preference getters with defaults
  def position_columns_preference
    get_preference('positions_table', 'columns', DEFAULT_POSITION_COLUMNS)
  end

  def dashboard_layout_preference
    get_preference('dashboard', 'layout', DEFAULT_DASHBOARD_LAYOUT)
  end
end
```

---

## Controller Implementation

### PreferencesController

```ruby
class PreferencesController < ApplicationController
  before_action :authenticate_user!

  # GET /preferences/:category/:key
  def show
    category = params[:category]
    key = params[:key]
    default = preference_defaults(category, key)

    preference = current_user.get_preference(category, key, default)

    render json: {
      category: category,
      key: key,
      value: preference
    }
  end

  # PUT /preferences/:category/:key
  def update
    category = params[:category]
    key = params[:key]
    value = params[:value]

    current_user.set_preference(category, key, value)

    render json: {
      success: true,
      category: category,
      key: key,
      value: value
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH /preferences/:category/:key/nested
  # For updating single nested value without replacing entire JSONB
  def update_nested
    category = params[:category]
    key = params[:key]
    path = params[:path]  # e.g., "columns.symbol.visible"
    value = params[:value]

    UserUiPreference.update_nested(current_user, category, key, path, value)

    render json: { success: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def preference_defaults(category, key)
    case [category, key]
    when ['positions_table', 'columns']
      DEFAULT_POSITION_COLUMNS
    when ['dashboard', 'layout']
      DEFAULT_DASHBOARD_LAYOUT
    when ['display', 'formats']
      DEFAULT_DISPLAY_FORMATS
    else
      {}
    end
  end
end
```

### Constants File (config/initializers/preference_defaults.rb)

```ruby
# Position table default columns
DEFAULT_POSITION_COLUMNS = {
  "symbol" => { "visible" => true, "order" => 1, "width" => 120 },
  "quantity" => { "visible" => true, "order" => 2, "width" => 80 },
  "ltp" => { "visible" => true, "order" => 3, "width" => 100 },
  "pnl_amount" => { "visible" => true, "order" => 4, "width" => 100 },
  "pnl_percent" => { "visible" => true, "order" => 5, "width" => 80 }
}.freeze

# All available columns (for UI builder)
AVAILABLE_POSITION_COLUMNS = [
  { key: "symbol", label: "Symbol", always_visible: true },
  { key: "weight_percent", label: "Weight %", always_visible: false },
  { key: "quantity", label: "Qty", always_visible: false },
  { key: "ltp", label: "LTP", always_visible: false },
  { key: "invested", label: "Invested", always_visible: false },
  { key: "current_value", label: "Current", always_visible: false },
  { key: "pnl_amount", label: "P&L", always_visible: false },
  { key: "pnl_percent", label: "P&L %", always_visible: false },
  { key: "sentiment_tag", label: "Tag", always_visible: false }
].freeze

# Dashboard layout defaults
DEFAULT_DASHBOARD_LAYOUT = {
  "widget_order" => ["stats_cards", "positions", "market_feed", "performance"],
  "stats_cards" => {
    "visible" => ["total_value", "cash", "pnl_today", "net_pnl"],
    "layout" => "grid"
  },
  "positions" => {
    "default_view" => "sections",
    "default_expanded" => true
  }
}.freeze

# Display format defaults
DEFAULT_DISPLAY_FORMATS = {
  "number_format" => "indian",
  "currency_symbol" => "₹",
  "date_format" => "dd/mm/yyyy",
  "time_format" => "24h",
  "timezone" => "Asia/Kolkata",
  "decimal_places" => {
    "currency" => 2,
    "percentage" => 2,
    "weight" => 1
  }
}.freeze
```

---

## View Implementation

### Positions Table with Preferences

```erb
<!-- app/views/dashboard/_holdings_section.html.erb -->
<%
  # Get user's column preferences
  columns_pref = current_user.position_columns_preference
  visible_columns = columns_pref.select { |k, v| v["visible"] }
                                 .sort_by { |k, v| v["order"] }
                                 .map(&:first)
%>

<div class="bg-container rounded-2xl border border-border p-6">
  <div class="flex items-center justify-between mb-6">
    <h2 class="text-xl font-semibold text-primary">Holdings</h2>

    <!-- Column Customization Gear Icon -->
    <button
      data-controller="dropdown"
      data-action="click->dropdown#toggle"
      class="text-sm text-secondary hover:text-primary">
      <svg class="w-5 h-5" fill="none" stroke="currentColor">
        <!-- Gear icon SVG -->
      </svg>
    </button>
  </div>

  <table class="w-full text-sm">
    <thead>
      <tr class="border-b border-border">
        <% if visible_columns.include?("symbol") %>
          <th class="text-left py-2 font-medium text-secondary">Symbol</th>
        <% end %>
        <% if visible_columns.include?("weight_percent") %>
          <th class="text-right py-2 font-medium text-secondary">Weight %</th>
        <% end %>
        <% if visible_columns.include?("quantity") %>
          <th class="text-right py-2 font-medium text-secondary">Qty</th>
        <% end %>
        <!-- ... other columns based on visible_columns ... -->
      </tr>
    </thead>
    <tbody>
      <% @holdings_by_section.each do |section| %>
        <% section.positions.each do |position| %>
          <tr class="border-b border-border hover:bg-gray-50">
            <% if visible_columns.include?("symbol") %>
              <td class="py-3">
                <div class="font-medium text-primary"><%= position.security.symbol %></div>
              </td>
            <% end %>
            <% if visible_columns.include?("weight_percent") %>
              <td class="text-right py-3 text-primary">
                <%= position.portfolio_weight_percent(@portfolio_stats[:total_value]) %>%
              </td>
            <% end %>
            <!-- ... other columns ... -->
          </tr>
        <% end %>
      <% end %>
    </tbody>
  </table>
</div>
```

### Column Settings Modal (Stimulus Component)

```javascript
// app/javascript/controllers/column_settings_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "orderInput"]
  static values = {
    category: String,
    key: String
  }

  async toggleColumn(event) {
    const checkbox = event.target
    const columnKey = checkbox.dataset.columnKey
    const visible = checkbox.checked

    // Update preference via API
    await fetch(`/preferences/${this.categoryValue}/${this.keyValue}/nested`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({
        path: `${columnKey}.visible`,
        value: visible
      })
    })

    // Reload table or update DOM directly
    this.reloadTable()
  }

  async saveOrder() {
    const order = {}
    this.orderInputTargets.forEach((input, index) => {
      const columnKey = input.dataset.columnKey
      order[columnKey] = { order: index + 1 }
    })

    await fetch(`/preferences/${this.categoryValue}/${this.keyValue}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({ value: order })
    })

    this.reloadTable()
  }

  reloadTable() {
    // Turbo Frame reload or manual DOM update
    Turbo.visit(window.location, { action: 'replace' })
  }

  get csrfToken() {
    return document.querySelector('[name="csrf-token"]').content
  }
}
```

---

## Migration Plan

### Phase 1: Foundation (Immediate)
1. Create `user_ui_preferences` table
2. Create `UserUiPreference` model with get/set methods
3. Add User association and convenience methods
4. Define `DEFAULT_POSITION_COLUMNS` constant
5. Create `PreferencesController` with show/update actions
6. Add routes: `resources :preferences, only: [:show, :update]`

### Phase 2: Position Table Integration
1. Update `_holdings_section.html.erb` to use preferences
2. Add gear icon with column settings dropdown
3. Create Stimulus controller for column toggling
4. Implement AJAX save of column preferences
5. Test column show/hide functionality

### Phase 3: Future Extensions (As Needed)
1. Dashboard layout preferences
2. Chart preferences
3. Display format preferences
4. Trades table column preferences
5. Watchlist table column preferences

---

## Routes

```ruby
# config/routes.rb
resources :preferences, only: [] do
  collection do
    get ':category/:key', action: :show, as: :get
    put ':category/:key', action: :update, as: :set
    patch ':category/:key/nested', action: :update_nested, as: :update_nested
  end
end

# Generates routes:
# GET    /preferences/:category/:key          → preferences#show
# PUT    /preferences/:category/:key          → preferences#update
# PATCH  /preferences/:category/:key/nested   → preferences#update_nested
```

---

## Benefits of This Strategy

### 1. **Extensibility**
- Add new preference types without database migrations
- JSONB allows any structure
- Single pattern works for all UI customizations

### 2. **Performance**
- GIN index on JSONB for fast queries
- Single table lookup instead of joins
- Defaults in memory (constants) for non-existent preferences

### 3. **User Experience**
- Settings persist across sessions
- Multi-device sync (same user, any device)
- Export/import preferences (future feature)

### 4. **Developer Experience**
- Simple API: `get_preference(category, key, default)`
- Type-safe with validation
- Easy to test and debug

### 5. **Future-Proof**
- Can add: theme preferences, widget layouts, keyboard shortcuts
- Can extend: per-account preferences (not just per-user)
- Can evolve: add versioning, A/B testing, admin overrides

---

## Testing Strategy

### Model Tests
```ruby
# test/models/user_ui_preference_test.rb
test "get returns default when preference doesn't exist" do
  user = users(:trader)
  pref = UserUiPreference.get(user, 'positions_table', 'columns', { default: true })
  assert_equal({ default: true }, pref)
end

test "set creates new preference" do
  user = users(:trader)
  value = { "symbol" => { "visible" => true } }
  UserUiPreference.set(user, 'positions_table', 'columns', value)

  pref = UserUiPreference.get(user, 'positions_table', 'columns')
  assert_equal value, pref
end
```

### Controller Tests
```ruby
# test/controllers/preferences_controller_test.rb
test "should get preference" do
  get get_preferences_path(category: 'positions_table', key: 'columns')
  assert_response :success
  assert_includes response.parsed_body["value"].keys, "symbol"
end

test "should update preference" do
  put set_preferences_path(
    category: 'positions_table',
    key: 'columns',
    value: { "symbol" => { "visible" => false } }
  )
  assert_response :success
end
```

---

## Next Steps

1. **Review this strategy** - Does it cover your needs?
2. **Confirm decisions:**
   - Use single `user_ui_preferences` table with JSONB?
   - Category + Key structure works for future extensions?
   - API endpoints acceptable (GET/PUT/PATCH)?
3. **Ready to implement?** - I can start building Phase 1 + 2

**Recommendation:** Approve this strategy, then I'll implement Phase 1 (foundation) and Phase 2 (position table) together. This gives you column customization immediately and a pattern for all future UI preferences.
