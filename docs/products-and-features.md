# TradeFlow Products & Features
## Comprehensive Feature Specification

### Product Architecture Overview

#### Technology Stack
- **Backend**: Ruby on Rails 7.2+ with PostgreSQL
- **Frontend**: Inertia.js with Vue.js/React components
- **Styling**: Tailwind CSS with custom trading-focused components
- **API Integration**: Zerodha Kite Connect API
- **Background Processing**: Sidekiq for data synchronization
- **Deployment**: Docker containers with cloud hosting

#### Core Database Schema
```sql
-- User Management
users (id, email, encrypted_password, subscription_plan, created_at)
profiles (id, user_id, display_name, bio, avatar_url, trading_since, preferred_timeframe)

-- Account Management (Multiple Zerodha Accounts per User)
trading_accounts (id, user_id, zerodha_user_id, api_key_encrypted, account_name, account_type, is_primary, created_at)
account_snapshots (id, trading_account_id, date, total_value, cash_balance, invested_amount, percent_deployed, day_pnl, created_at)

-- Securities & Market Data (Centralized - Synced Once for All Users)
securities (id, symbol, nse_symbol, company_name, sector, industry, exchange, last_price, day_change, day_change_percent, last_updated)
market_data (id, security_id, date, open, high, low, close, volume, adj_close)
price_updates (id, security_id, price, timestamp) -- Real-time price stream for active trading hours

-- User Custom Analysis (Manual Entry)
user_stock_analysis (id, user_id, security_id, user_stage, user_rs_rank, user_notes, last_updated_by_user)

-- Trading Records (Account-Specific)
trades (id, trading_account_id, user_id, security_id, trade_type, entry_date, exit_date, quantity, entry_price, exit_price, pnl, status)
positions (id, trading_account_id, user_id, security_id, quantity, avg_cost, current_price, unrealized_pnl, last_updated)

-- Journal & Analysis
journal_entries (id, trade_id, user_id, strategy_used, entry_rationale, exit_rationale, lessons_learned, screenshots, user_stage, user_rs_rank, risk_amount, position_size_rationale)
trade_tags (id, trade_id, tag_name, tag_category)
performance_metrics (id, user_id, period_start, period_end, total_trades, win_rate, avg_profit_loss, max_drawdown)
risk_settings (id, trading_account_id, user_id, max_risk_per_trade, max_portfolio_risk, position_sizing_method, stop_loss_method)

-- Social Features (Phase 3 - Post MVP)
social_posts (id, user_id, content, trade_id, visibility, likes_count, comments_count, created_at)
social_comments (id, post_id, user_id, content, created_at)
social_likes (id, post_id, user_id, created_at)
user_follows (id, follower_id, following_id, created_at)

-- Watchlists & Custom Data
watchlists (id, user_id, name, description, is_public, created_at)
watchlist_items (id, watchlist_id, security_id, price_alert, target_price, stop_loss, added_at)
-- Note: user_stage, user_rs_rank, user_notes come from user_stock_analysis table
```

---

## Core Features

### 1. User Authentication & Profile Management

#### 1.1 Account Setup
- **Email/Password Registration**: Standard sign-up with email verification
- **Multiple Zerodha Account Integration**: Connect multiple Zerodha accounts via OAuth
- **Profile Customization**: Display name, bio, trading experience, risk tolerance
- **Privacy Settings**: Control visibility of trades and social interactions

#### 1.2 Multi-Account Management
- **Account Connection**: Connect multiple Zerodha accounts (Personal, Family, HUF, etc.)
- **Account Naming**: Custom names for each account (Aggressive, Conservative, Options, etc.)
- **Account Switching**: Easy switching between accounts in the interface
- **Account Overview**: Consolidated view of all accounts with key metrics
- **Account-Specific Settings**: Different risk settings and strategies per account

#### 1.3 Subscription Management
- **Free Tier**: Basic journaling for up to 50 trades/month
- **Pro Tier** (₹299/month): Unlimited trades, advanced analytics, social features
- **Elite Tier** (₹999/month): Real-time data, custom screening, priority support

#### 1.4 Security Features
- **Two-Factor Authentication**: SMS and app-based 2FA
- **API Key Encryption**: Secure storage of Zerodha credentials
- **Session Management**: Automatic logout, device tracking
- **Data Privacy**: GDPR-compliant data handling

---

### 2. Trading Journal Core

#### 2.1 Automated Trade Import
- **Zerodha Integration**: Automatic sync of completed trades
- **Trade Classification**: Auto-categorize by strategy type (Stage 2 breakout, SEPA entry, etc.)
- **Position Tracking**: Real-time updates of open positions
- **Historical Data**: Import past 2 years of trading history

**User Story**: *"As a trader, I want my Zerodha trades automatically imported so I don't have to manually enter each transaction."*

#### 2.2 Manual Trade Entry
- **Quick Entry Form**: Symbol search, entry/exit prices, quantities
- **Strategy Selection**: Dropdown for user-defined strategies (Stage 1 breakout, SEPA setup, etc.)
- **Stage Input**: User enters current Weinstein stage (1, 2, 3, 4)
- **RS Rank Input**: User enters relative strength assessment (1-10 scale)
- **Trade Rationale**: Rich text field for entry reasoning
- **Screenshot Upload**: Chart screenshots with annotation tools
- **Risk Management**: Stop loss, target price, risk amount fields

**Implementation Details**:
```ruby
class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :security
  has_one :journal_entry
  has_many :trade_tags

  enum trade_type: { long: 0, short: 1 }
  enum status: { open: 0, closed: 1, partial: 2 }

  validates :entry_price, :quantity, presence: true
  validates :exit_price, presence: true, if: :closed?
end
```

#### 2.3 Journal Entry Management
- **Rich Text Editor**: Markdown support for formatting trade notes
- **Template System**: Pre-built templates for Weinstein and Minervini strategies
- **Custom Fields**: User-defined stage, RS rank, market condition assessment
- **Tag Management**: Custom tags for categorization and filtering
- **Lesson Tracking**: Separate section for lessons learned
- **Risk Analysis**: Post-trade review of risk management decisions

**Features**:
- Before/after chart comparison
- Emotion tracking (fear, greed, confidence levels)
- Market condition notes (user assessment)
- Strategy adherence scoring
- Position sizing rationale and review

---

### 3. Risk Management & Position Sizing

#### 3.1 Risk Management Framework
- **Risk Per Trade**: User-defined maximum risk percentage per trade
- **Portfolio Risk**: Total risk across all open positions
- **Position Sizing Calculator**: Calculate shares based on risk amount and stop loss
- **Risk/Reward Tracking**: Monitor R-multiples for each trade

**Risk Management Implementation**:
```ruby
class RiskManagementService
  def calculate_position_size(account_size, risk_percentage, entry_price, stop_loss)
    risk_amount = account_size * (risk_percentage / 100.0)
    risk_per_share = entry_price - stop_loss
    position_size = risk_amount / risk_per_share
    position_size.floor
  end

  def portfolio_heat(user_id)
    # Calculate total risk across all open positions
  end
end
```

#### 3.2 User-Driven Stage Tracking
- **Manual Stage Input**: Users assign stages based on their analysis
- **Stage History**: Track user's stage assessments over time
- **Stage Performance**: Analyze success rate by stage entry
- **Custom Stage Notes**: Rich text notes for stage rationale

#### 3.3 Custom Analysis Fields
- **User RS Assessment**: 1-10 relative strength rating (user input)
- **Market Condition**: User assessment of overall market (bull/bear/neutral)
- **Sector Strength**: User rating of sector performance
- **Setup Quality**: User rating of trade setup (1-5 stars)

---

### 4. Watchlist Management

#### 4.1 Automated Data (Centralized Zerodha API Sync)
- **Real-time Prices**: Live price updates via shared WebSocket connection during market hours
- **Company Information**: Name, sector, industry, exchange synced once for all users
- **Price Changes**: Day change, percentage change, 52-week high/low from central data
- **Market Data**: OHLCV data fetched once and shared across all user portfolios/watchlists
- **Efficient Scaling**: Same stock data serves unlimited users without API multiplication

#### 4.2 Manual User Analysis (Stock-Level)
- **Weinstein Stage**: User assigns stage 1-4 based on their analysis
- **Relative Strength**: User rates RS on 1-10 scale (10 = strongest)
- **Analysis Notes**: Rich text notes for stage rationale and observations
- **Global Stock Data**: When user updates Reliance to Stage 2, RS 8.2 - it's available across all watchlists and portfolio views

#### 4.3 Watchlist Features
- **Multiple Lists**: Create unlimited custom watchlists (Breakouts, Stage 2 Pullbacks, etc.)
- **Price Alerts**: Set target and stop loss price alerts via email/SMS
- **Performance Tracking**: Track how watchlist picks perform over time
- **List Sharing**: Share watchlists with community (stages and RS visible to followers)
- **Quick Add**: Add stocks to watchlist directly from portfolio or search

**Technical Implementation**:
```ruby
class Security < ApplicationRecord
  has_many :user_stock_analyses
  has_many :watchlist_items
  has_many :price_updates

  # Centralized data - updated once for all users
  scope :actively_tracked, -> {
    joins(:watchlist_items, :positions).distinct
  }

  def self.sync_metadata_from_zerodha!
    # Run once daily - updates company info for all securities
    MarketDataSyncService.new.sync_all_securities_metadata
  end

  def current_price
    # Returns latest price from centralized sync
    price_updates.last&.price || last_price
  end
end

class UserStockAnalysis < ApplicationRecord
  belongs_to :user
  belongs_to :security

  validates :user_stage, inclusion: { in: [1, 2, 3, 4] }
  validates :user_rs_rank, inclusion: { in: 1..10 }
  validates :user_notes, length: { maximum: 1000 }

  # One analysis record per user per stock
  validates :security_id, uniqueness: { scope: :user_id }

  def security_with_live_price
    # Combines user analysis with centralized pricing
    security.attributes.merge(
      user_stage: user_stage,
      user_rs_rank: user_rs_rank,
      current_price: security.current_price
    )
  end
end

# Centralized price sync - serves all users
class PriceUpdate < ApplicationRecord
  belongs_to :security

  scope :latest_for_security, ->(security_id) {
    where(security_id: security_id).order(:timestamp).last
  }
end
```

#### 4.4 What's NOT Available
- **Automated Stage Detection**: No algorithmic stage classification
- **Automated RS Calculation**: No computed relative strength rankings
- **Fundamental Screening**: No EPS growth, P/E ratio filtering
- **Technical Indicators**: No automated moving averages, RSI, MACD
- **Pattern Recognition**: No cup-and-handle, VCP detection

---

### 5. Data Export & Reporting (Phase 1)

#### 5.1 CSV Export Features
- **Complete Trade History**: All trades with entry/exit data, P&L, and custom fields
- **Performance Metrics**: Win rate, profit factor, R-multiples by date range
- **Watchlist Data**: All watchlists with user stage/RS assessments
- **Account Summaries**: Multi-account performance and deployment data
- **Custom Filters**: Export specific strategies, date ranges, or accounts

#### 5.2 PDF Report Generation
- **Monthly Performance Reports**: Automated reports with charts and key metrics
- **Quarterly Reviews**: Comprehensive performance analysis with insights
- **Tax Reports**: ITR-ready trade summaries with STCG/LTCG classification
- **Account Statements**: Professional-grade portfolio summaries
- **Custom Reports**: User-defined report templates

#### 5.3 Technical Implementation
```ruby
class ReportExportService
  def generate_csv_export(user, options = {})
    # Generate comprehensive CSV with trade data, performance metrics
    # Support filtering by date, account, strategy
  end

  def generate_pdf_report(user, report_type, period)
    # Use Prawn gem for PDF generation
    # Include charts via ChartKick/Plotly integration
    # Professional formatting for tax/compliance use
  end
end
```

---

### 6. Advanced Analytics (Phase 2+)

#### 6.1 Trade Performance Metrics
- **Win Rate**: Percentage of profitable trades
- **Profit Factor**: Gross profit / gross loss ratio
- **Average R**: Average trade return relative to risk
- **Maximum Drawdown**: Largest peak-to-trough decline
- **Sharpe Ratio**: Risk-adjusted returns

#### 6.2 Strategy Analysis
- **Strategy Breakdown**: Performance by strategy type
- **Timeframe Analysis**: Performance by holding period
- **Market Condition Performance**: Bull vs. bear market results
- **Sector Performance**: Best and worst performing sectors

#### 6.3 Behavioral Analytics
- **Trade Discipline Score**: Adherence to predefined rules
- **Emotional Trading Indicators**: Revenge trading, FOMO detection
- **Improvement Tracking**: Progress over time metrics
- **Goal Setting**: Monthly/quarterly performance targets

#### 6.4 Advanced Visualization
- **Interactive Charts**: Plotly.js-powered performance visualizations
- **Real-time Dashboard**: Live P&L and position tracking
- **Custom Dashboards**: User-configurable analytics views

---

### 7. Performance Analytics & Reporting

#### 7.1 Trade Performance Metrics
- **Win Rate**: Percentage of profitable trades
- **Average R-Multiple**: Average return relative to initial risk
- **Profit Factor**: Gross profit / gross loss ratio
- **Maximum Drawdown**: Largest peak-to-trough decline
- **Strategy Performance**: Performance breakdown by user-defined strategy

#### 7.2 Risk Analytics
- **Risk-Adjusted Returns**: Sharpe ratio and risk metrics
- **Position Sizing Analysis**: Review of sizing decisions
- **Stop Loss Analysis**: Effectiveness of stop loss placement
- **Portfolio Heat Tracking**: Historical risk exposure levels

#### 7.3 Export & Reporting (Phase 1 Features)
- **CSV Export**: Complete trade history, performance metrics, watchlists
- **PDF Reports**: Monthly/quarterly performance summaries with charts
- **Tax Reports**: Formatted trade summaries for tax filing (ITR format)
- **Account Reports**: Multi-account consolidated or individual reports
- **Custom Date Ranges**: Export data for any specified period

#### 7.4 Advanced Analytics (Phase 2+)
- **Trade Discipline**: Adherence to user-defined rules
- **Emotional Trading**: Identify revenge trading or FOMO patterns
- **Stage Analysis Accuracy**: Success rate by stage entry
- **Improvement Tracking**: Progress metrics over time
- **Interactive Dashboards**: Advanced visualizations and drill-downs

---

### 8. Social Features (Phase 3 - Post MVP)

#### 8.1 Trading Community
- **Trading Feed**: Share trade ideas, completed trade reviews, market observations
- **User Profiles**: Display verified performance stats and strategy specialization
- **Following System**: Follow other traders for feed updates and learning
- **Privacy Controls**: Public, followers-only, or private posts

#### 8.2 Community Interactions
- **Trade Discussions**: Comment threads on shared trades
- **Strategy Groups**: Focused communities around specific methodologies
- **Watchlist Sharing**: Share watchlists with community (stages and RS visible)
- **Mentorship**: Connect experienced traders with beginners

#### 8.3 Social Features
- **Performance Verification**: Link to broker statements for credibility
- **Anonymous Mode**: Option to hide actual P&L numbers
- **Rich Media Support**: Charts, screenshots, trade annotations
- **Trade Linking**: Link social posts to actual trades in journal

---

### 9. Mobile Strategy

#### 9.1 Phase 1: Progressive Web App (PWA)
- **Mobile-Responsive Design**: Tailwind CSS mobile-first approach
- **PWA Installation**: App-like experience on mobile devices
- **Core Mobile Features**: Portfolio overview, trade entry, journal updates
- **Fast Loading**: Optimized for Indian mobile networks
- **Cross-platform**: Single codebase for iOS/Android experience

#### 9.2 Phase 2: Native Mobile Apps
- **iOS/Android Apps**: Native development for enhanced performance
- **Offline Capability**: Core functionality without internet connection
- **Camera Integration**: Quick chart screenshot capture and annotation
- **Voice Notes**: Audio trade rationale recording with transcription
- **Push Notifications**: Real-time price alerts and account updates
- **Biometric Security**: Face ID/Touch ID for secure app access
- **Apple Watch/WearOS**: Quick portfolio overview on smartwatches

#### 9.3 Mobile-Specific Features (Phase 2)
- **Quick Trade Entry**: Streamlined mobile trade logging interface
- **Photo Journal**: Direct camera integration for chart captures
- **Location-Based Notes**: Tag trades with location metadata
- **Dark Mode**: Mobile-optimized dark theme for trading hours

---

## Technical Implementation Details

### API Architecture

#### Centralized Market Data Sync (Application Level)
```ruby
# Global Market Data Service - Runs once for all users
class MarketDataSyncService
  def initialize
    @kite = KiteConnect::Client.new(api_key: ENV['KITE_MASTER_API_KEY'])
  end

  def sync_all_securities_metadata
    # Sync company info, sector, industry for all NSE/BSE stocks
    # Runs once daily or when new securities are added
  end

  def sync_real_time_prices
    # WebSocket connection for live prices during market hours
    # Updates securities.last_price for all actively tracked stocks
    # Serves all users from this single data stream
  end

  def sync_historical_data(symbol_list)
    # Batch fetch OHLCV data for securities in any user's portfolio/watchlist
    # Optimized to avoid duplicate API calls
  end
end

# User-Specific Portfolio Sync
class UserPortfolioSyncService
  def initialize(trading_account)
    @account = trading_account
    @kite = KiteConnect::Client.new(
      api_key: ENV['KITE_API_KEY'],
      access_token: @account.decrypted_access_token
    )
  end

  def sync_positions_and_trades
    # Sync user's actual positions and completed trades
    # Links to centralized securities table for pricing
  end

  def sync_account_summary
    # Update account value, cash balance, margins
    # Store in account_snapshots for historical tracking
  end
end

# Background Jobs
class MarketDataSyncJob < ApplicationJob
  queue_as :high_priority

  def perform
    MarketDataSyncService.new.sync_real_time_prices
  end
end

class UserAccountSyncJob < ApplicationJob
  queue_as :default

  def perform(trading_account_id)
    account = TradingAccount.find(trading_account_id)
    UserPortfolioSyncService.new(account).sync_positions_and_trades
  end
end
```

#### Data Architecture Benefits
- **Single API Rate Limit**: One master connection for pricing data
- **Cost Efficiency**: Avoid duplicate API calls for same stock across users
- **Consistent Data**: All users see same price at same time
- **Scalability**: Add 1000 users without 1000x API calls
- **Real-time Performance**: WebSocket connection shared across all users

### Performance Considerations
- **Database Indexing**: Optimized indexes for trade queries
- **Caching Strategy**: Redis for frequently accessed data
- **Background Processing**: Async jobs for heavy computations
- **CDN Integration**: Fast image/screenshot delivery

### Security Measures
- **API Rate Limiting**: Prevent abuse of Zerodha API calls
- **Data Encryption**: Sensitive trading data encryption at rest
- **Audit Logging**: Track all user actions for security
- **Regular Backups**: Automated daily database backups

---

## MVP (Minimum Viable Product) Definition

### Phase 1: Core Journal & Risk Management (Months 1-3)
- User registration and multiple Zerodha account connection
- Multi-account management with account-level analytics
- Automated trade import from all connected Zerodha accounts
- Account snapshots (total value, % deployed, cash balance tracking)
- Manual trade entry with custom fields (stage, RS rank, strategy)
- Journal entries with screenshots and risk analysis
- Position sizing calculator and account-specific risk management
- Basic performance metrics and R-multiple tracking per account
- Watchlist management with manual data entry
- **CSV/PDF Export**: Trade reports, performance summaries, tax reports
- **Mobile-responsive PWA**: Optimized web interface for mobile devices

### Phase 2: Advanced Analytics & Native Mobile (Months 4-6)
- Advanced performance analytics and detailed reporting
- **Native mobile apps** (iOS/Android) with offline capability
- Custom templates and trade setup checklists
- Enhanced risk management tools and portfolio heat maps
- Advanced filtering and search capabilities
- Multi-timeframe performance analysis
- Automated price alerts and notifications

### Phase 3: Post-MVP Enhancements (Months 7+)
- **Social features**: Trading feed, user following, community interactions
- **Community features**: Watchlist sharing, trade discussions, mentorship
- Additional broker integrations (Angel One, Upstox, IIFL)
- Advanced analytics and pattern recognition
- Educational content and strategy guides
- API access for power users
- Advanced automation and workflow tools

---

## Success Metrics & KPIs

### User Engagement
- **Daily Active Users**: Target 40% of registered users
- **Session Duration**: Average 15+ minutes per session
- **Feature Adoption**: 80% use automated trade import
- **Community Participation**: 60% engage with social features

### Business Metrics
- **Monthly Recurring Revenue**: ₹10 lakhs by Month 12
- **Customer Acquisition Cost**: <₹500 per paid user
- **Lifetime Value**: ₹15,000+ per customer
- **Churn Rate**: <5% monthly churn

### Product Performance
- **Trade Import Accuracy**: 99%+ automated trade matching
- **User Data Quality**: 85%+ of trades have complete journal entries
- **API Uptime**: 99.9% availability for Zerodha integration
- **Page Load Speed**: <2 seconds for all core pages

---

## User Stories: What Users Can Do

### Story 1: Portfolio Sync and Manual Stage Assignment
**As a momentum trader**, I want to connect my Zerodha account and see my current positions with live prices, so I can manually assign stages to each stock based on my analysis.

**What I get automatically:**
- Live portfolio sync from Zerodha
- Current prices, day change, P&L for each position
- Company name, sector, industry information

**What I enter manually:**
- Weinstein stage (1-4) for each stock in my portfolio
- Relative strength rank (1-10) based on my analysis
- Notes about why I assigned that stage

**What's not available:**
- Automated stage detection or RS calculation
- Buy/sell recommendations

---

### Story 2: Trade Import and Journal Entry
**As a trader**, I want my completed trades automatically imported from Zerodha so I can add my trade rationale and lessons learned without manual data entry.

**What I get automatically:**
- All completed trades imported (symbol, quantity, entry/exit prices, dates)
- Automatic P&L calculation
- Link to the stock's current price and sector info

**What I enter manually:**
- Strategy used (Stage 2 breakout, SEPA setup, etc.)
- Entry and exit rationale
- Stage I thought the stock was in when I bought
- Lessons learned and emotional state during trade
- Screenshots of charts

**What's not available:**
- Automated trade classification or strategy detection
- Automated performance analysis

---

### Story 3: Position Sizing and Risk Management
**As a risk-conscious trader**, I want to calculate position sizes based on my risk tolerance and stop loss levels, so I can maintain consistent risk across all trades.

**What I get automatically:**
- Current account value from Zerodha
- Real-time price for position sizing calculations
- Portfolio heat calculation across all open positions

**What I enter manually:**
- Maximum risk per trade (e.g., 2% of account)
- Stop loss level for each position
- Risk/reward target for trade planning

**What's not available:**
- Automated stop loss suggestions
- Volatility-based position sizing

---

### Story 4: Watchlist Creation with Stage Analysis
**As a momentum trader**, I want to create watchlists organized by stages and maintain my analysis across all lists, so when I update Reliance to Stage 2, it shows Stage 2 everywhere.

**What I get automatically:**
- Real-time prices for all watchlist stocks
- Sector and industry classification
- Price alerts when stocks hit my target/stop levels

**What I enter manually:**
- Stage assignment (1-4) for each stock (saved globally)
- RS rank (1-10) for relative strength assessment
- Notes about setup quality and reasons for watching
- Target entry price and stop loss levels

**What's not available:**
- Automated watchlist population based on criteria
- Algorithmic stage change detection

---

### Story 5: CSV and PDF Export for Records
**As a systematic trader**, I want to export my trade data and performance reports in CSV and PDF formats so I can maintain external records and file taxes efficiently.

**What I get automatically:**
- Complete trade history with all custom fields in CSV format
- Professional PDF reports with charts and performance metrics
- ITR-ready tax reports with STCG/LTCG classification
- Multi-account consolidated or individual account reports

**What I enter manually:**
- Selection of date ranges and accounts for export
- Choice of report type (monthly, quarterly, tax, custom)
- Custom filters for specific strategies or trade types

**What's not available:**
- Automated tax filing integration
- External portfolio management software sync

---

### Story 6: Performance Analytics and Reporting
**As a data-driven trader**, I want to see which stages and strategies work best for me, so I can improve my trading approach over time.

**What I get automatically:**
- Win rate, profit factor, average R-multiple calculations
- Performance breakdown by strategy type and stage entry
- Monthly and quarterly performance summaries
- Risk-adjusted return metrics

**What I enter manually:**
- Custom performance goals and targets
- Trade classification and strategy tags
- Market condition assessment for each trade period

**What's not available:**
- Benchmark comparison against indices
- Predictive analytics or future performance forecasting

---

### Story 7: Multi-Device Trading Journal Access
**As a mobile trader**, I want to access my journal and update trade information from my phone during market hours, so I can log trades and emotions in real-time.

**What I get automatically:**
- Responsive web interface that works on mobile
- Real-time price updates for portfolio and watchlists
- Push notifications for price alerts

**What I enter manually:**
- Quick trade notes via voice-to-text
- Photos of charts directly from phone camera
- Emotional state and confidence level during trades

**What's not available:**
- Native mobile app (in Phase 1)
- Offline functionality

---

### Story 8: Custom Analysis Templates
**As a systematic trader**, I want pre-built templates for different strategies so I can consistently evaluate setups using Weinstein and Minervini criteria.

**What I get automatically:**
- Current stock price and basic market data
- Historical performance of similar setups (from my past trades)

**What I enter manually:**
- Checklist completion for SEPA criteria
- Stage analysis rationale using Weinstein framework
- Setup quality rating (1-5 stars)
- Risk/reward assessment for the trade

**What's not available:**
- Automated scoring or grading of setups
- Algorithmic template recommendations

---

### Story 9: Mobile Progressive Web App Access
**As a mobile trader**, I want to access my trading journal and update trade information from my smartphone so I can log trades and emotions in real-time during market hours.

**What I get automatically:**
- Mobile-responsive interface that works seamlessly on all devices
- PWA installation for app-like experience
- Real-time portfolio and price updates on mobile
- Fast loading optimized for Indian mobile networks

**What I enter manually:**
- Quick trade notes and journal entries via mobile
- Photos of charts directly from phone camera
- Emotional state and confidence level during trades
- Mobile-friendly watchlist management

**What's not available:**
- Native mobile app features (Phase 2 only)
- Offline functionality
- Voice-to-text integration

---

### Story 10: Risk Portfolio Heat Map
**As a portfolio manager**, I want to see my total risk exposure across all positions so I can avoid over-concentration and maintain proper diversification.

**What I get automatically:**
- Current position values from Zerodha
- Real-time portfolio value and day change
- Risk calculation based on my stop loss levels
- Sector concentration analysis

**What I enter manually:**
- Stop loss levels for each position
- Maximum portfolio risk tolerance
- Correlation concerns between positions

**What's not available:**
- Automated correlation analysis
- Dynamic stop loss adjustments
- Algorithmic portfolio rebalancing suggestions

---

### Story 11: Multi-Account Management and Capital Allocation
**As a professional trader**, I want to manage multiple Zerodha accounts with different strategies and track capital deployment, account growth, and risk allocation across all accounts from a single dashboard.

**What I get automatically:**
- Sync of all connected Zerodha accounts (Personal, Family, HUF, etc.)
- Real-time account values, cash balances, and invested amounts for each account
- Daily snapshots of % deployed capital per account
- Automatic calculation of month-over-month account growth/decline
- Consolidated portfolio view across all accounts
- Account-specific P&L and performance tracking

**What I enter manually:**
- Account names and types (Personal, Conservative, Aggressive, Family, etc.)
- Account-specific risk settings (max risk per trade, max portfolio exposure)
- Capital allocation strategy between accounts
- Account goals and objectives
- Manual capital additions/withdrawals logging

**What's not available:**
- Automated capital allocation suggestions between accounts
- Cross-account correlation analysis
- Automated rebalancing recommendations

**Example Usage:**
- Account 1: "Personal Aggressive" - ₹10L total, 85% deployed, 2.5% account growth this month
- Account 2: "Family Conservative" - ₹5L total, 60% deployed, 1.2% account growth this month
- Account 3: "Options Trading" - ₹2L total, 45% deployed, -0.8% account decline this month

**Technical Implementation:**
```ruby
class TradingAccount < ApplicationRecord
  belongs_to :user
  has_many :trades
  has_many :positions
  has_many :account_snapshots
  has_one :risk_setting

  validates :account_name, presence: true
  validates :zerodha_user_id, uniqueness: true

  def current_deployment_percentage
    return 0 if total_value.zero?
    (invested_amount / total_value) * 100
  end

  def monthly_growth(month = Date.current.beginning_of_month)
    start_snapshot = account_snapshots.find_by(date: month)
    current_value = total_value
    return 0 unless start_snapshot

    ((current_value - start_snapshot.total_value) / start_snapshot.total_value) * 100
  end
end
```

**Account Dashboard Features:**
- Account switcher in top navigation
- Account-specific performance charts
- Capital deployment heat map across accounts
- Monthly growth comparison between accounts
- Risk utilization per account (current risk vs. max allowed)
- Account-wise sector and strategy allocation

---

## Data Flow Summary

**Automated (Zerodha API):**
- Portfolio positions and trades
- Real-time prices and market data
- Company information and sector classification
- P&L calculations

**Manual User Entry:**
- Weinstein stages (1-4)
- Relative strength rankings (1-10)
- Trade rationales and strategies
- Risk management decisions
- Analysis notes and observations

**Not Available:**
- Automated technical analysis
- Algorithmic pattern recognition
- Fundamental data screening
- Predictive analytics or signals