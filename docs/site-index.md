# TradeFlow Site Index
## Complete Page & Navigation Structure

**Purpose**: Master inventory of all pages, routes, and navigation hierarchy for TradeFlow MVP.

---

## Navigation Structure

### Primary Navigation (Top Level)

1. **Dashboard** - `/` (root)
2. **Positions** - `/positions` (TBD)
3. **Feed** - `/feed` (TBD)
4. **Trades** - `/trades`
5. **Journal** - `/journal` (TBD)
6. **Analytics** - `/analytics`
7. **Settings** - `/settings` (TBD - dropdown menu)

### Settings Submenu (Dropdown)

1. **Account Settings** - `/settings/account`
2. **Trading Accounts** - `/trading_accounts`
3. **Preferences** - `/settings/preferences`
4. **Billing** - `/settings/billing`
5. **Security** - `/settings/security`
6. **API Keys** - `/settings/api_keys` (future)

---

## Page Inventory

### 1. Dashboard (`/`)
**Status**: ✅ Built (dashboard#index)
**Controller**: `DashboardController#index`
**Route**: `root "dashboard#index"`
**Views**:
- `app/views/dashboard/portfolio.html.erb` (current implementation)
- Partials in `app/views/dashboard/_*.html.erb`

**Purpose**: Primary landing page showing portfolio overview, holdings, and key metrics.

**Content Sections**:
- **Stat Cards** (4 cards in grid):
  - Total Portfolio Value
  - Cash Balance (with % of total)
  - P&L Today
  - Net P&L (all-time)
- **Holdings Sections** (collapsible):
  - Core Holdings
  - Probe Holdings
  - Custom sections (user-created)
  - Positions table per section
- **Market Feed**:
  - Market indices (NIFTY, SENSEX, BANKNIFTY)
  - News feed (basic implementation)
  - Live/News toggle
- **Performance Chart**:
  - Time period selector (1D, 1W, 1M, 1Y, ALL)
  - Portfolio value over time chart
  - Performance metrics summary

**Key Features**:
- Multi-account view (if user has multiple Zerodha accounts)
- Drag-and-drop positions between sections
- Real-time price updates (during market hours)
- Quick action buttons (Add Position, Create Section, etc.)

**Spec Location**: [docs/design-specs.md](design-specs.md) - "Already Built" section

---

### 2. Positions (`/positions`)
**Status**: 🔴 Not Built (route exists, no index view)
**Controller**: `PositionsController#index` (needs to be created)
**Route**: `resources :positions` (currently only has member actions)
**Views**: TBD

**Purpose**: Full CRUD management of all positions across all accounts.

**Content Sections**:
- **Page Header**:
  - Title: "All Positions"
  - Filter bar: Account, Status (Open/Closed), Strategy, Section
  - Sort options: Symbol, Weight%, P&L, Date Added
  - Export buttons: CSV, PDF
  - Actions: Add Position, Bulk Edit

- **Summary Bar** (sticky top):
  - Total Positions Count
  - Total Invested Amount
  - Total Current Value
  - Total Unrealized P&L
  - Total Unrealized P&L %

- **Positions Table** (full-width):
  - Columns (user-configurable via preferences):
    - ☑ Symbol (always visible)
    - ☐ Section (which holding section)
    - ☐ Weight % (portfolio weight)
    - ☑ Quantity
    - ☑ Avg Price (average cost basis)
    - ☑ LTP (Last Traded Price)
    - ☐ Invested (cost basis)
    - ☐ Current Value
    - ☑ Unrealized P&L (₹)
    - ☑ Unrealized P&L (%)
    - ☐ Day Change (₹)
    - ☐ Day Change (%)
    - ☐ Tags (buy/sell sentiment - future)
    - ☑ Actions (Edit, Close, Move, Delete)

- **Row Actions**:
  - Edit Position (inline or modal)
  - Close Position (creates exit trade)
  - Move to Section (dropdown selector)
  - Delete Position (with confirmation)
  - View Trade History (link to trades for this symbol)

- **Bulk Actions** (when rows selected):
  - Move to Section
  - Tag Positions
  - Export Selected
  - Delete Selected

**User Stories**:
- View all positions across all accounts in one table
- Filter positions by account, status, or strategy
- Customize which columns to display
- Sort positions by any metric
- Bulk edit positions (move to sections, tag, etc.)
- Export position data to CSV/PDF

**Implementation Requirements**:
- Reuse `Position` model (already exists)
- Create `PositionsController#index` action
- Build positions table view
- Integrate with `user_ui_preferences` for column customization
- Add filtering and sorting logic
- Implement bulk actions

**Related Features**:
- See [design-specs.md](design-specs.md) Feature #1: Table Column Customization
- See [design-specs.md](design-specs.md) Feature #2: Position Weight Calculation

---

### 3. Feed (`/feed`)
**Status**: 🔴 Not Built
**Controller**: `FeedController` (needs to be created)
**Route**: TBD - `get "/feed", to: "feed#index"`
**Views**: TBD

**Purpose**: Market news, social trading feed, and community insights.

**Content Sections**:
- **Feed Tabs**:
  - **Live** (default): Real-time market updates and price movements
  - **News**: Curated news from Bloomberg, Reuters, Economic Times, etc.
  - **Community** (Phase 3): Social posts from traders user follows
  - **Alerts**: Price alerts, watchlist notifications, account activity

- **Live Feed** (default tab):
  - Market indices ticker (scrolling)
  - Top gainers/losers (NSE/BSE)
  - Unusual volume alerts
  - Sector performance heatmap
  - User's watchlist price movements

- **News Feed**:
  - News cards with metadata:
    - Source badge (e.g., "Bloomberg", "AI Insights", "Goldman Sachs")
    - Author attribution
    - Timestamp (relative: "9m ago", "1h ago")
    - Headline + description
    - Ticker tags ($NVDA, $AAPL, etc.) - clickable
    - Engagement metrics: upvotes, comments count
    - Sentiment tag ("bullish", "bearish", "neutral")
  - Actions per news item:
    - Upvote/downvote
    - Comment (opens comment thread)
    - Share (copy link)
    - Add stock to watchlist (from ticker tags)

- **Community Feed** (Phase 3):
  - Trade ideas from followed traders
  - Completed trade reviews
  - Watchlist shares
  - Market observations
  - User can like, comment, share

- **Alerts**:
  - Price alerts (watchlist stocks hit target/stop)
  - Account notifications (large deposits, unusual activity)
  - System notifications (sync errors, data updates)

**Filters & Actions**:
- Filter by: Source, Sentiment, Ticker, Time Period
- Search: Free-text search within news/posts
- Mark all as read
- Notification preferences (link to Settings)

**User Stories**:
- See latest market news aggregated from multiple sources
- Engage with news via upvotes/comments (social features)
- Track stocks mentioned in news via ticker tags
- Filter news by sentiment or source
- Receive price alerts and account notifications in one feed

**Implementation Requirements**:
- Create `FeedController` with `index` action
- Create `MarketNewsItem`, `NewsVote`, `NewsComment` models (see design-specs.md Feature #4)
- Build news aggregation service (API integration or seed data)
- Build feed view with tabs (Live, News, Community, Alerts)
- Implement upvote/downvote functionality (AJAX)
- Implement comment threading
- Add ticker tag parsing and clickability

**Related Features**:
- See [design-specs.md](design-specs.md) Feature #4: Enhanced Market Feed
- See [products-and-features.md](products-and-features.md) Social Features (Phase 3)

---

### 4. Trades (`/trades`)
**Status**: ✅ Partially Built (index exists, needs enhancement)
**Controller**: `TradesController#index`
**Route**: `resources :trades`
**Views**:
- `app/views/trades/index.html.erb` (exists, basic implementation)
- `app/views/trades/_trade.html.erb` (partial, needs enhancement)

**Purpose**: Complete trade history and management across all accounts.

**Content Sections**:
- **Page Header**:
  - Title: "Trade History"
  - Filter bar: Account, Date Range, Status (Open/Closed/Partial), Strategy, Symbol
  - Sort options: Date, Symbol, P&L, R-multiple, Duration
  - Export buttons: CSV (trade data), PDF (trade report)
  - Actions: Add Trade, Import Trades (from Zerodha)

- **Summary Cards** (4 cards):
  - Total Trades (filtered count)
  - Win Rate (% profitable trades)
  - Average P&L (₹ per trade)
  - Average R-Multiple (risk-adjusted return)

- **Trades Table**:
  - Columns:
    - ☑ Date (entry date)
    - ☑ Symbol (stock ticker)
    - ☑ Type (Long/Short)
    - ☑ Strategy (user-defined: Stage 2 Breakout, SEPA, etc.)
    - ☑ Entry Price
    - ☑ Exit Price (if closed)
    - ☑ Quantity
    - ☑ P&L (₹)
    - ☑ P&L (%)
    - ☑ R-Multiple (if journal entry exists)
    - ☑ Duration (days held)
    - ☑ Status (Open/Closed/Partial)
    - ☑ Journal (icon: ✓ if entry exists, ✗ if missing)
    - ☑ Actions (Edit, Close, Delete, View Journal)

- **Row Actions**:
  - Edit Trade (inline or modal)
  - Close Trade (if open, prompts for exit price)
  - View/Add Journal Entry (link to journal page)
  - Delete Trade (with confirmation)
  - Duplicate Trade (quick re-entry for similar setup)

- **Bulk Actions**:
  - Tag trades (bulk strategy assignment)
  - Export selected trades
  - Delete selected trades

- **Pagination**:
  - Show 50 trades per page
  - Load more (infinite scroll) or numbered pagination

**User Stories**:
- View complete trade history across all accounts
- Filter trades by date, account, strategy, or symbol
- Sort trades by any metric
- Quickly identify trades missing journal entries
- Export trade data for tax filing or external analysis
- Close open trades and log exit prices

**Implementation Requirements**:
- Enhance existing `TradesController#index` with filtering/sorting
- Add summary calculations (win rate, avg P&L, avg R-multiple)
- Build advanced filters (date range picker, multi-select)
- Add export functionality (CSV/PDF)
- Implement bulk actions
- Add "missing journal" indicator
- Link to journal entry page per trade

**Related Features**:
- See [spec.md](spec.md) Milestone 3: Trade Management
- See [products-and-features.md](products-and-features.md) Section 2: Trading Journal Core

---

### 5. Journal (`/journal`)
**Status**: 🔴 Not Built
**Controller**: `JournalEntriesController` (needs to be created)
**Route**: TBD - `resources :journal_entries` or `get "/journal", to: "journal_entries#index"`
**Views**: TBD

**Purpose**: Trading journal with detailed trade rationale, screenshots, and lessons learned.

**Content Sections**:

#### 5.1 Journal Index (`/journal`)
- **Page Header**:
  - Title: "Trading Journal"
  - Filter bar: Date Range, Strategy, Symbol, Stage, Has Screenshots, Has Lessons
  - Sort options: Date (newest first), P&L, R-multiple
  - Actions: New Journal Entry, Link to Trade

- **Journal Entries List** (card-based layout):
  - Each card shows:
    - Date + Symbol + Strategy
    - Entry rationale (truncated, 2-3 lines)
    - Screenshot thumbnail (if exists)
    - P&L badge (green/red)
    - R-multiple badge
    - Tags (stage, user-defined tags)
    - Actions: View, Edit, Delete

- **Empty State**:
  - "No journal entries yet"
  - CTA: "Add your first journal entry" (links to new form)
  - CTA: "Import trades and start journaling" (links to trades page)

#### 5.2 Journal Entry Show/Edit (`/journal/:id`)
- **Trade Summary** (read-only, top section):
  - Symbol, Entry Date, Exit Date (if closed)
  - Entry Price, Exit Price, Quantity
  - P&L (₹), P&L (%), R-multiple
  - Account (which Zerodha account)

- **Journal Form** (editable sections):

  **Section 1: Strategy & Analysis**
  - Strategy dropdown (user-defined strategies)
  - Weinstein Stage (1-4, user input)
  - Relative Strength Rank (1-10 scale, user input)
  - Market Condition (bull/bear/neutral, user assessment)
  - Setup Quality (1-5 stars, user rating)

  **Section 2: Entry Rationale**
  - Rich text editor (Markdown or WYSIWYG)
  - Screenshot upload (drag-drop, multiple files)
  - Screenshot annotation tools (arrows, text, highlights)
  - Chart checklist:
    - ☐ Stage 2 base completion
    - ☐ Pocket pivot or volume surge
    - ☐ RS line at new high
    - ☐ 50-day MA rising
    - ☐ Volume 40%+ above average
    - (User-defined checklist based on strategy template)

  **Section 3: Risk Management**
  - Stop Loss Price (user input)
  - Target Price (user input)
  - Risk Amount (₹, auto-calculated or user override)
  - R-Multiple Target (e.g., 3R, 5R)
  - Position Size Rationale (free text: why this size?)

  **Section 4: Exit Rationale** (only for closed trades)
  - Exit Reason dropdown (Target Hit, Stop Hit, Strategy Exit, Mistake, etc.)
  - Exit Notes (rich text)
  - Was Exit Planned? (Yes/No)
  - Emotion at Exit (dropdown: Fear, Greed, Confidence, Panic, Calm)

  **Section 5: Lessons Learned**
  - What Went Well (rich text)
  - What Went Wrong (rich text)
  - Key Takeaway (single line, tweet-length)
  - Strategy Adherence Score (1-5: did I follow my rules?)
  - Tags (user-defined: "revenge trade", "FOMO", "disciplined", etc.)

  **Section 6: Screenshots & Attachments**
  - Chart screenshots (before entry, during hold, after exit)
  - Broker statements (if applicable)
  - Annotation tools per image
  - Delete/reorder images

- **Actions**:
  - Save Draft (auto-save every 30 seconds)
  - Publish Entry
  - Delete Entry
  - Share Entry (Phase 3: social features)
  - Export as PDF (individual trade report)

#### 5.3 New Journal Entry (`/journal/new`)
- Same form as Edit view
- Option to link to existing trade (dropdown search)
- Option to create standalone journal entry (for manual analysis)

**User Stories**:
- Log detailed rationale for every trade (entry and exit)
- Upload and annotate chart screenshots
- Track lessons learned over time
- Use strategy templates for consistent analysis (SEPA checklist, Weinstein checklist)
- Review journal entries to identify patterns (emotional trading, rule violations, etc.)
- Export journal entries as PDF reports

**Implementation Requirements**:
- Create `JournalEntry` model (already exists in schema, see spec.md)
- Create `JournalEntriesController` with full CRUD
- Build journal index view (card-based layout)
- Build journal form view (6 sections as above)
- Implement screenshot upload and annotation (Active Storage + annotation library)
- Implement rich text editor (ActionText or Trix)
- Add strategy templates (seed data + UI for custom templates)
- Add auto-save functionality (Stimulus controller + AJAX)
- Add PDF export per journal entry (Prawn gem)

**Related Features**:
- See [spec.md](spec.md) Milestone 3.3: Trading Journal
- See [products-and-features.md](products-and-features.md) Section 2.3: Journal Entry Management

---

### 6. Analytics (`/analytics`)
**Status**: ✅ Partially Built (basic view exists)
**Controller**: `DashboardController#analytics`
**Route**: `get "/analytics", to: "dashboard#analytics"`
**Views**:
- `app/views/dashboard/analytics.html.erb` (exists, needs enhancement)

**Purpose**: Advanced performance analytics, metrics, and visualizations.

**Content Sections**:

#### 6.1 Overview Tab (default)
- **Time Period Selector** (sticky top):
  - Presets: 1W, 1M, 3M, 6M, 1Y, YTD, All Time
  - Custom date range picker
  - Account filter (single or "All Accounts")

- **Key Metrics Cards** (6 cards in grid):
  - Total Trades (count)
  - Win Rate (% profitable)
  - Profit Factor (gross profit / gross loss)
  - Average R-Multiple (risk-adjusted return)
  - Max Drawdown (% decline from peak)
  - Sharpe Ratio (if enough data)

- **Performance Chart** (full-width):
  - Portfolio value over time (line chart)
  - Benchmark comparison (NIFTY 50, optional)
  - Drawdown overlay (area chart below zero)
  - Toggle: Linear vs. Log scale

- **Monthly Performance Heatmap**:
  - Calendar heatmap showing monthly returns
  - Color-coded: green (profit), red (loss), gray (neutral)
  - Click month → drill down to trades that month

#### 6.2 Strategy Analysis Tab
- **Performance by Strategy** (bar chart):
  - Win rate per strategy
  - Avg P&L per strategy
  - Avg R-multiple per strategy
  - Trade count per strategy

- **Strategy Breakdown Table**:
  - Columns: Strategy Name, Trades, Win Rate, Avg P&L, Avg R, Profit Factor
  - Sort by any column
  - Click strategy → filter trades page to that strategy

- **Stage Analysis** (if user logs stages):
  - Performance by entry stage (Stage 1, 2, 3, 4)
  - Win rate by stage
  - Best performing stage (data-driven insight)

#### 6.3 Risk Analysis Tab
- **Risk Metrics Cards**:
  - Average Risk Per Trade (% of account)
  - Max Risk Per Trade (highest % risked)
  - Current Portfolio Heat (total risk across open positions)
  - Risk/Reward Ratio (avg target/stop ratio)

- **Risk vs. Reward Scatter Plot**:
  - X-axis: Risk per trade (% of account)
  - Y-axis: Reward (R-multiple)
  - Each dot = one trade
  - Color: green (winner), red (loser)
  - Insight: Are you risking too much for too little reward?

- **Stop Loss Effectiveness**:
  - % of trades stopped out
  - Average slippage (actual exit vs. planned stop)
  - Emotional stops vs. planned stops

#### 6.4 Trade Duration Tab
- **Holding Period Analysis**:
  - Average holding period (days)
  - Performance by holding period:
    - Intraday (< 1 day)
    - Swing (1-7 days)
    - Short-term (7-30 days)
    - Medium-term (30-90 days)
    - Long-term (90+ days)

- **Duration vs. P&L Chart**:
  - X-axis: Holding period (days)
  - Y-axis: P&L (%)
  - Scatter plot with trendline
  - Insight: Do you hold winners long enough?

#### 6.5 Behavioral Insights Tab (Phase 2)
- **Trade Discipline Score**:
  - % of trades with complete journal entries
  - % of trades following predefined strategy rules
  - % of trades with planned stop losses
  - Overall discipline score (0-100)

- **Emotional Trading Indicators**:
  - Revenge trades detected (trades within 1 hour of loss)
  - FOMO trades (chasing price after breakout)
  - Overtrading days (>X trades in one day)
  - Calendar: emotion tags per trade (from journal)

- **Improvement Tracking**:
  - Win rate over time (rolling 20-trade average)
  - Avg R-multiple over time (trend chart)
  - Progress toward goals (user-defined targets)

#### 6.6 Export & Reports
- **Generate Report** (button in top-right):
  - Monthly Performance Report (PDF)
  - Quarterly Review (PDF with charts)
  - Tax Report (CSV with STCG/LTCG classification)
  - Custom Report (user selects metrics, date range, format)

- **Scheduled Reports** (future):
  - Email reports weekly/monthly
  - Auto-export to Google Drive/Dropbox

**User Stories**:
- See comprehensive performance metrics at a glance
- Analyze which strategies work best for me
- Identify risk management strengths and weaknesses
- Track improvement over time
- Generate professional reports for personal review or sharing
- Identify behavioral patterns (revenge trading, FOMO, etc.)

**Implementation Requirements**:
- Enhance `DashboardController#analytics` with calculations
- Build analytics service (`AnalyticsService` or `PerformanceCalculator`)
- Implement chart visualizations (Chart.js or Plotly.js)
- Add tabs for different analysis views
- Implement PDF report generation (Prawn gem)
- Add export functionality (CSV for raw data)
- Implement behavioral insights (Phase 2)

**Related Features**:
- See [spec.md](spec.md) Milestone 4: Risk Management & Analytics
- See [products-and-features.md](products-and-features.md) Section 6: Advanced Analytics

---

### 7. Settings (`/settings`)
**Status**: 🔴 Not Built (placeholder route needed)
**Controller**: `SettingsController` (needs to be created)
**Route**: TBD - `get "/settings", to: "settings#index"` or redirect to first submenu item
**Views**: TBD - Settings landing page or redirect to Account Settings

**Purpose**: Central hub for all user settings and configuration.

**Layout**:
- **Sidebar Navigation** (left, 200px wide):
  - Account Settings
  - Trading Accounts
  - Preferences
  - Billing
  - Security
  - API Keys (future)
  - Help & Support

- **Main Content Area** (right, full-width minus sidebar):
  - Dynamic content based on selected submenu item

---

### 7.1 Account Settings (`/settings/account`)
**Status**: 🔴 Not Built
**Controller**: `Settings::AccountsController` (needs to be created)
**Route**: TBD - `namespace :settings { resource :account }`
**Views**: TBD

**Purpose**: User profile and account information management.

**Content Sections**:
- **Profile Information**:
  - Display Name (editable)
  - Email Address (editable, requires verification)
  - Avatar Upload (Active Storage, WebP variant)
  - Bio/About (rich text, 500 char limit)
  - Trading Since (year dropdown, e.g., "2019")
  - Preferred Timeframe (dropdown: Intraday, Swing, Position, Long-term)

- **Account Details** (read-only):
  - User ID (for support)
  - Account Created Date
  - Last Login
  - Subscription Plan (Free/Pro/Elite)

- **Danger Zone**:
  - Change Password (link to password change form)
  - Export All Data (download complete data dump as JSON/CSV)
  - Delete Account (requires confirmation, irreversible)

- **Actions**:
  - Save Changes (validates email, saves profile)
  - Cancel (resets form)

**User Stories**:
- Update my profile information
- Change my email address
- Upload a profile avatar
- Export all my data for personal records
- Delete my account if I want to leave

**Implementation Requirements**:
- Create `Settings::AccountsController`
- Add profile fields to User model (if not exists)
- Implement avatar upload (Active Storage)
- Add email change workflow (send verification email)
- Implement account deletion (soft delete or hard delete?)
- Build account settings form view

---

### 7.2 Trading Accounts (`/trading_accounts`)
**Status**: ✅ Partially Built (index exists)
**Controller**: `TradingAccountsController#index`
**Route**: `resources :trading_accounts`
**Views**:
- `app/views/trading_accounts/index.html.erb` (exists, basic implementation)

**Purpose**: Manage connected Zerodha accounts and account-specific settings.

**Content Sections**:
- **Connected Accounts List**:
  - Each account card shows:
    - Account Name (editable inline, e.g., "Personal Aggressive")
    - Zerodha User ID (read-only)
    - Account Type (dropdown: Personal, Family, HUF, Joint)
    - Is Primary? (toggle, one account must be primary)
    - Connection Status (Connected / Disconnected / Error)
    - Last Synced (timestamp)
    - Actions: Edit, Disconnect, Sync Now, View Details

- **Add Account Button** (top-right):
  - Click → OAuth flow to connect new Zerodha account
  - Link to Zerodha Kite Connect authorization

- **Account Details View** (expandable or separate page):
  - Account Summary:
    - Total Value, Cash Balance, Invested Amount
    - % Deployed, Month-over-Month Growth
  - Risk Settings (per account):
    - Max Risk Per Trade (% of account)
    - Max Portfolio Risk (% of account)
    - Position Sizing Method (Fixed %, ATR-based, Manual)
    - Stop Loss Method (Fixed %, ATR-based, Technical)
  - Sync Settings:
    - Auto-sync frequency (15 min, 30 min, 1 hour, Manual only)
    - Sync during market hours only (toggle)
  - Actions:
    - Save Risk Settings
    - Force Full Sync (re-sync all positions and trades)
    - View Account History (link to trades filtered by this account)

**User Stories**:
- Connect multiple Zerodha accounts (Personal, Family, etc.)
- Name and organize my accounts
- Set different risk parameters per account
- Monitor connection status and sync errors
- Manually trigger sync if data is stale
- Disconnect an account I no longer want to track

**Implementation Requirements**:
- Enhance `TradingAccountsController` with edit/update actions
- Implement Zerodha OAuth connection flow (Kite Connect API)
- Add account risk settings (create `RiskSetting` model if not exists)
- Build account card component (collapsible details)
- Add manual sync action (background job trigger)
- Implement disconnect flow (soft delete account or archive)

**Related Features**:
- See [spec.md](spec.md) Milestone 2: Zerodha Integration
- See [products-and-features.md](products-and-features.md) Section 1.2: Multi-Account Management

---

### 7.3 Preferences (`/settings/preferences`)
**Status**: ✅ Partially Built (controller exists, no UI)
**Controller**: `PreferencesController`
**Route**:
```ruby
resources :preferences, only: [] do
  collection do
    get ':category/:key', action: :show, as: :get
    put ':category/:key', action: :update, as: :set
  end
end
```
**Views**: TBD - needs settings UI

**Purpose**: User interface preferences and customization.

**Content Sections**:

#### Display Preferences
- **Theme**:
  - Light Mode (default)
  - Dark Mode (future)
  - Auto (follow system preference)

- **Number Formatting**:
  - Indian Format (2,50,000) - default
  - International Format (250,000)
  - Compact (2.5L, 2.5Cr)

- **Currency Display**:
  - Symbol (₹)
  - Code (INR)
  - Both (₹ INR)

- **Date Format**:
  - DD/MM/YYYY (default for India)
  - MM/DD/YYYY
  - YYYY-MM-DD

#### Table Preferences
- **Positions Table Columns** (see Feature #1 in design-specs.md):
  - Checkboxes for each column:
    - ☑ Symbol (always visible, disabled checkbox)
    - ☐ Section
    - ☐ Weight %
    - ☑ Quantity
    - ☑ LTP
    - ☐ Invested
    - ☐ Current Value
    - ☑ P&L (₹)
    - ☑ P&L (%)
    - ☐ Day Change (₹)
    - ☐ Day Change (%)
    - ☐ Tags
  - Drag-to-reorder columns (future)

- **Trades Table Columns**:
  - Similar checkboxes for trades table

- **Rows Per Page**:
  - Dropdown: 25, 50, 100, 200

#### Dashboard Preferences
- **Default View**:
  - Portfolio (default)
  - Analytics
  - Trades

- **Stat Cards to Show** (4 cards, fixed positions):
  - Total Value (always shown)
  - Cash (toggle on/off)
  - P&L Today (toggle on/off)
  - Net P&L (toggle on/off)

- **Holdings Sections**:
  - Default Collapsed/Expanded (toggle)
  - Show Empty Sections (toggle)

#### Notification Preferences (future)
- Email Notifications:
  - Daily summary (toggle)
  - Weekly report (toggle)
  - Price alerts (toggle)
  - Trade sync errors (toggle)

- SMS Notifications:
  - Price alerts only (toggle)

- Push Notifications (PWA/Native app):
  - All notifications (toggle)

#### Data & Privacy
- **Data Retention**:
  - Keep trade data: Forever, 5 years, 2 years

- **Analytics Tracking**:
  - Allow anonymous usage analytics (toggle)

- **Export Defaults**:
  - Default format: CSV, PDF, Excel
  - Include screenshots in exports (toggle)

**Actions**:
- Save Preferences (AJAX save per section)
- Reset to Defaults (confirmation modal)

**User Stories**:
- Customize which columns I see in positions/trades tables
- Set my preferred number format (Indian vs. international)
- Choose default dashboard view
- Control email and SMS notifications
- Manage data retention and privacy settings

**Implementation Requirements**:
- Create `Settings::PreferencesController` or use existing `PreferencesController`
- Build preferences UI (tabbed layout or accordion)
- Implement AJAX save per preference change (instant feedback)
- Use existing `user_ui_preferences` table (see design-specs.md)
- Add preference seed defaults for new users
- Implement reset to defaults functionality

**Related Features**:
- See [design-specs.md](design-specs.md) Feature #1: Table Column Customization
- See [docs/ui-preferences-strategy.md](ui-preferences-strategy.md) for implementation strategy

---

### 7.4 Billing (`/settings/billing`)
**Status**: 🔴 Not Built
**Controller**: `Settings::BillingsController` (needs to be created)
**Route**: TBD - `namespace :settings { resource :billing }`
**Views**: TBD

**Purpose**: Subscription management, payment history, and invoices.

**Content Sections**:

#### Current Plan
- **Plan Card**:
  - Plan Name (Free, Pro, Elite)
  - Price (₹0, ₹299/month, ₹999/month)
  - Features included (bullet list)
  - Billing Period (Monthly, Yearly)
  - Next Billing Date (if paid plan)
  - Status (Active, Canceled, Past Due, Trial)

- **Actions**:
  - Upgrade Plan (if Free → shows Pro/Elite options)
  - Downgrade Plan (if Pro/Elite → shows lower tiers)
  - Change Billing Frequency (Monthly ↔ Yearly)
  - Cancel Subscription (with confirmation)

#### Payment Method
- **Current Payment Method**:
  - Card: **** **** **** 1234 (Visa)
  - Expiry: 12/2025
  - Actions: Update, Remove

- **Add Payment Method**:
  - Razorpay or Stripe integration
  - Support: Credit/Debit cards, UPI, Net Banking

#### Billing History
- **Invoices Table**:
  - Columns: Date, Plan, Amount, Status, Invoice
  - Row actions: Download PDF, View Details
  - Pagination (show last 12 months by default)

- **Filters**:
  - Date range
  - Status (Paid, Pending, Failed, Refunded)

#### Usage & Limits (for Free tier users)
- **Current Usage**:
  - Trades this month: 42 / 50
  - Progress bar (84% used)
  - Warning: "You're close to your monthly limit. Upgrade to Pro for unlimited trades."

- **Actions**:
  - Upgrade Now (CTA button)

**User Stories**:
- View my current subscription plan and features
- Upgrade or downgrade my plan
- Update my payment method
- View and download past invoices
- Monitor my usage limits (if on Free plan)
- Cancel my subscription if needed

**Implementation Requirements**:
- Create `Settings::BillingsController`
- Integrate payment gateway (Razorpay for India or Stripe)
- Create `Subscription` model (if not exists)
- Create `Invoice` model for billing history
- Implement plan upgrade/downgrade logic
- Build billing UI (plan cards, payment form, invoice table)
- Implement invoice PDF generation
- Add usage tracking for Free tier limits

**Related Features**:
- See [products-and-features.md](products-and-features.md) Section 1.3: Subscription Management

---

### 7.5 Security (`/settings/security`)
**Status**: 🔴 Not Built
**Controller**: `Settings::SecurityController` (needs to be created)
**Route**: TBD - `namespace :settings { resource :security }`
**Views**: TBD

**Purpose**: Security settings, password management, and two-factor authentication.

**Content Sections**:

#### Password Management
- **Change Password**:
  - Current Password (input, required)
  - New Password (input, strength indicator)
  - Confirm New Password (input)
  - Actions: Update Password, Cancel

- **Password Strength Requirements**:
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one number
  - At least one special character

#### Two-Factor Authentication (2FA)
- **2FA Status**:
  - Enabled / Disabled (badge)
  - If enabled: "Last used: 2 hours ago"

- **Enable 2FA** (if disabled):
  - Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
  - Enter verification code
  - Save backup codes (download or print)

- **Disable 2FA** (if enabled):
  - Requires password confirmation
  - Warning: "Your account will be less secure"

- **Backup Codes**:
  - View Backup Codes (if 2FA enabled)
  - Regenerate Backup Codes (invalidates old codes)

#### Active Sessions
- **Current Session** (this device):
  - Device: Windows PC - Chrome
  - Location: Mumbai, India (approximate)
  - IP: 103.x.x.x
  - Last Active: Just now

- **Other Sessions**:
  - List of all active sessions:
    - Device + Browser
    - Location (city, country)
    - IP address
    - Last Active (timestamp)
    - Actions: Revoke Session

- **Actions**:
  - Revoke All Other Sessions (keeps current session only)

#### Login History (last 30 days)
- **Recent Logins Table**:
  - Columns: Date/Time, Device, Location, IP, Status (Success/Failed)
  - Filters: Successful only, Failed only, All
  - Download CSV (for security audit)

#### API Access (future)
- **API Keys**:
  - Create API key for third-party integrations
  - View existing API keys (name, created date, last used)
  - Revoke API keys

**User Stories**:
- Change my password securely
- Enable two-factor authentication for added security
- View and manage active login sessions
- Revoke sessions from devices I no longer use
- Review login history for suspicious activity
- Generate API keys for third-party tools (future)

**Implementation Requirements**:
- Create `Settings::SecurityController`
- Implement password change logic (with current password verification)
- Implement 2FA setup (TOTP gem or devise-two-factor)
- Add session tracking (create `UserSession` model or use Devise trackable)
- Build login history tracking (create `LoginAttempt` model)
- Implement session revocation (destroy session tokens)
- Build security settings UI
- Add IP geolocation for session locations (GeoIP gem)

**Related Features**:
- See [products-and-features.md](products-and-features.md) Section 1.4: Security Features

---

### 7.6 API Keys (`/settings/api_keys`)
**Status**: 🔴 Not Built (Future Phase)
**Controller**: `Settings::ApiKeysController` (future)
**Route**: TBD - `namespace :settings { resources :api_keys }`
**Views**: TBD

**Purpose**: Manage API keys for third-party integrations and programmatic access.

**Content Sections**:
- **API Keys List**:
  - Each key shows:
    - Key Name (user-defined, e.g., "My Trading Bot")
    - Key (partially masked: `tf_xxxxxxxxxxxxxxxx1234`)
    - Created Date
    - Last Used (timestamp)
    - Permissions (Read-only, Read/Write)
    - Status (Active, Revoked)
    - Actions: Copy Key, Revoke, Delete

- **Create New API Key**:
  - Key Name (input)
  - Permissions (dropdown: Read-only, Read/Write)
  - Expiration (optional, dropdown: Never, 30 days, 90 days, 1 year)
  - Actions: Generate Key

- **API Documentation Link**:
  - Link to API docs (future)

- **Rate Limits**:
  - Current Usage: 1,234 / 10,000 requests per day
  - Upgrade to Elite for higher limits

**User Stories**:
- Generate API keys for custom integrations
- Revoke API keys I no longer use
- Monitor API usage and rate limits
- Access API documentation

**Implementation Requirements** (Future):
- Create `Settings::ApiKeysController`
- Create `ApiKey` model with token generation
- Implement API authentication middleware
- Build API keys UI
- Create API documentation (future)
- Implement rate limiting (Rack::Attack gem)

---

## Authentication & Onboarding Pages

### 8. Registration (`/signup`)
**Status**: ✅ Built
**Controller**: `UsersController#new, #create`
**Route**: `get "/signup", to: "users#new"`
**Views**: `app/views/users/new.html.erb`

**Purpose**: New user registration.

**Content**:
- Email input
- Password input (with strength indicator)
- Confirm Password input
- Terms of Service checkbox
- Sign Up button
- Link to Login page

---

### 9. Login (`/login`)
**Status**: ✅ Built
**Controller**: `SessionsController#new, #create`
**Route**: `get "/login", to: "sessions#new"`
**Views**: TBD (needs to be created)

**Purpose**: User login.

**Content**:
- Email input
- Password input
- Remember Me checkbox
- Login button
- Links: Forgot Password?, Sign Up

---

### 10. Onboarding Flow (`/onboarding`)
**Status**: ✅ Built
**Controller**: `OnboardingsController#show, #trading_profile, #first_account, #initial_data`
**Routes**:
```ruby
resource :onboarding, only: :show do
  collection do
    get :trading_profile
    get :first_account
    get :initial_data
  end
end
```
**Views**: TBD (4 separate views)

**Purpose**: Guide new users through initial setup.

**Steps**:
1. **Profile** (`/onboarding`) - Complete user profile
2. **Trading Profile** (`/onboarding/trading_profile`) - Trading style, risk tolerance, goals
3. **First Account** (`/onboarding/first_account`) - Connect first Zerodha account
4. **Initial Data** (`/onboarding/initial_data`) - Choose data path (Zerodha sync, Manual, Watchlist)

---

## Additional Pages (Future)

### 11. Watchlists (`/watchlists`)
**Status**: 🔴 Not Built (Future)
**Purpose**: Manage multiple watchlists and track potential trades.

### 12. Screener (`/screener`)
**Status**: 🔴 Not Built (Future - Phase 2+)
**Purpose**: Screen stocks based on user criteria (Stage 2, RS rank, volume, etc.).

### 13. Community (`/community`)
**Status**: 🔴 Not Built (Future - Phase 3)
**Purpose**: Social trading features, user profiles, following system.

### 14. Reports (`/reports`)
**Status**: 🔴 Not Built (Future - Phase 2)
**Purpose**: Generate and download custom reports (PDF/CSV).

---

## Route Summary

### Routes to Create (Priority Order)

**High Priority (MVP)**:
1. `get "/settings", to: "settings#index"` (or redirect to account settings)
2. `namespace :settings { resource :account }`
3. `namespace :settings { resource :preferences }`
4. `namespace :settings { resource :billing }`
5. `namespace :settings { resource :security }`
6. `get "/feed", to: "feed#index"`
7. `resources :journal_entries` or `get "/journal", to: "journal_entries#index"`
8. Enhance `resources :positions` to include `index` action

**Medium Priority (Post-MVP)**:
9. `resources :watchlists` with `resources :watchlist_items`
10. `resources :market_news_items` with `resources :news_votes, :news_comments`
11. `get "/screener", to: "screener#index"` (Phase 2)

**Low Priority (Future)**:
12. `get "/community", to: "community#index"` (Phase 3)
13. `resources :social_posts` (Phase 3)
14. `namespace :settings { resources :api_keys }` (Phase 3)

---

## Navigation Hierarchy (Final)

```
Primary Navigation (Top Bar):
├── Dashboard (/)
├── Positions (/positions)
├── Feed (/feed)
├── Trades (/trades)
├── Journal (/journal)
├── Analytics (/analytics)
└── Settings (dropdown)
    ├── Account Settings (/settings/account)
    ├── Trading Accounts (/trading_accounts)
    ├── Preferences (/settings/preferences)
    ├── Billing (/settings/billing)
    ├── Security (/settings/security)
    └── API Keys (/settings/api_keys) [future]

Secondary Pages:
├── Watchlists (/watchlists) [future]
├── Screener (/screener) [Phase 2]
└── Community (/community) [Phase 3]

Authentication:
├── Sign Up (/signup)
├── Login (/login)
├── Forgot Password (/password/reset)
└── Onboarding (/onboarding)
    ├── Profile (/onboarding)
    ├── Trading Profile (/onboarding/trading_profile)
    ├── First Account (/onboarding/first_account)
    └── Initial Data (/onboarding/initial_data)
```

---

## Implementation Checklist

### Phase 1: MVP Pages (12 weeks)
- [x] Dashboard (done)
- [x] Trades (basic, needs enhancement)
- [x] Trading Accounts (basic, needs enhancement)
- [ ] Positions (index view)
- [ ] Feed (news and market updates)
- [ ] Journal (full CRUD)
- [ ] Analytics (enhance existing)
- [ ] Settings (all 5 submenu items)

### Phase 2: Advanced Features (8 weeks)
- [ ] Watchlists (full CRUD)
- [ ] Screener (basic version)
- [ ] Reports (PDF/CSV generation)
- [ ] Enhanced analytics (behavioral insights)
- [ ] Mobile PWA optimization

### Phase 3: Social & Community (12 weeks)
- [ ] Community feed
- [ ] User profiles
- [ ] Social posts and interactions
- [ ] Watchlist sharing
- [ ] API access

---

## Next Steps

1. **Review this site index with stakeholders** - Are we missing any critical pages?
2. **Prioritize page specs** - Which pages do you want detailed specs for first?
3. **Create detailed page specs** - One markdown file per page with:
   - Wireframe/mockup (if available)
   - Component breakdown
   - Data requirements
   - User interactions
   - Implementation notes

**Recommended Order for Page Specs**:
1. Positions (high-value, completes core trading workflow)
2. Feed (user engagement, sticky feature)
3. Journal (core value proposition)
4. Settings (all 5 submenu items together)
5. Analytics (enhancement of existing page)

---

**Status Legend**:
- ✅ Built - Page exists and is functional
- 🟡 Partially Built - Page exists but needs significant enhancement
- 🔴 Not Built - Page doesn't exist yet, needs to be created
- 🔵 Future - Post-MVP, not planned for Phase 1
