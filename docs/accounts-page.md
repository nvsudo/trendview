# TradeFlow Accounts Page Specification
## Settings → Accounts: Trading Account Management & Cash Ledger

**Document Purpose:** Define the features, user experience, and implementation requirements for the Accounts management page within Settings.

**Context:** In TradeFlow, an "Account" refers to a trading account (e.g., Personal Growth, Retirement, Aggressive Trading). The relationship is: User → N Trading Accounts → N Trades → Derived Positions.

---

## Page 1: Executive Summary & Vision

### Purpose of the Accounts Page

The Accounts page serves as the **financial control center** for traders managing multiple trading accounts. It provides:

1. **Account Configuration:** Modify account names, types, and broker connections
2. **Cash Ledger Management:** Track deposits, withdrawals, and cash balance history
3. **Risk Settings:** Configure account-specific risk appetite and position sizing rules
4. **Account Performance:** View account-level metrics and capital deployment

### Product Vision Alignment

**From [vision.md](vision.md):**
> "Simple, powerful journal that connects strategy with community for momentum traders"

**How Accounts Page Supports This:**
- **Simple:** Clean interface for managing what matters - capital and risk
- **Powerful:** Precise cash tracking enables accurate performance measurement
- **Strategy-First:** Account-specific risk settings align with trader methodology

### Target User Needs

**Rahul** (IT Professional, Part-time Trader):
- Manages 2 accounts: Personal (₹5L) and Retirement (₹3L)
- Needs to track deposits from salary and annual withdrawals
- Wants different risk settings: 2% per trade (Personal) vs 1% (Retirement)

**Priya** (Full-time Trader, SEPA Methodology):
- Manages 3 accounts: Aggressive (₹10L), Conservative (₹5L), Options (₹2L)
- Frequently moves cash between accounts based on opportunity
- Requires strict risk controls per account strategy

### Key Differentiators vs Competitors

| Feature | Seeking Alpha | Edgewonk | TradingView | TradeFlow |
|---------|--------------|----------|-------------|-----------|
| Cash Ledger | Auto-sync only | Manual D/W tab | No ledger | **Manual + Auto-sync** |
| Multi-Account | Basic tracking | Unlimited accounts | Paper trading only | **Account-level settings** |
| Risk Settings | None | Global only | Per-trade drawing | **Per-account presets** |
| Indian UX | No | No | No | **₹ formatting, tax context** |
| Methodology Focus | Investment | Generic | Charting | **Momentum trading** |

---

## Page 2: Feature Specifications

### Feature 1: Account List & Overview

**User Story:**
> As a trader with multiple accounts, I want to see all my accounts at a glance with key metrics, so I can quickly understand my capital allocation and performance across accounts.

**UI Layout:**

```
┌─────────────────────────────────────────────────────────────┐
│ Settings → Accounts                                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [+ Add New Trading Account]                                 │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Personal Growth                     [Edit] [Settings]│   │
│  │ Zerodha • Personal • Connected                       │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ Account Size: ₹5,24,350    Cash: ₹1,24,350 (23.7%) │   │
│  │ Deployed: ₹4,00,000 (76.3%)                         │   │
│  │ Month Growth: +2.4%    Risk/Trade: 2.0%            │   │
│  │                                                       │   │
│  │ [View Cash Ledger] [Manage Risk Settings]           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Retirement Portfolio            [Edit] [Settings]    │   │
│  │ Zerodha • Retirement • Connected                     │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ Account Size: ₹3,00,000    Cash: ₹50,000 (16.7%)   │   │
│  │ Deployed: ₹2,50,000 (83.3%)                         │   │
│  │ Month Growth: +1.2%    Risk/Trade: 1.0%            │   │
│  │                                                       │   │
│  │ [View Cash Ledger] [Manage Risk Settings]           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- **Account Card:** Shows account name, broker, connection status
- **Key Metrics:** Account size, cash balance, % deployed, monthly growth
- **Quick Actions:** Edit account details, view cash ledger, manage risk settings
- **Visual Indicators:**
  - 🟢 Green dot: API connected and syncing
  - 🟡 Yellow dot: Manual account (no API)
  - 🔴 Red dot: API disconnected (needs re-auth)

**Technical Implementation:**
```ruby
# app/views/settings/accounts/index.html.erb
<% @trading_accounts.each do |account| %>
  <div class="account-card bg-container rounded-2xl border p-6 mb-4">
    <div class="flex justify-between items-start mb-4">
      <div>
        <h3 class="text-lg font-semibold text-primary"><%= account.account_name %></h3>
        <p class="text-sm text-secondary">
          <%= account.broker_name %> • <%= account.account_type %> •
          <span class="<%= account.connection_status_class %>">
            <%= account.connection_status %>
          </span>
        </p>
      </div>
      <div class="flex gap-2">
        <%= link_to "Edit", edit_settings_account_path(account), class: "btn-secondary-sm" %>
        <%= link_to "Settings", settings_account_path(account), class: "btn-secondary-sm" %>
      </div>
    </div>

    <div class="grid grid-cols-2 gap-4 mb-4">
      <div>
        <p class="text-sm text-secondary">Account Size</p>
        <p class="text-2xl font-semibold text-primary">
          ₹<%= number_with_delimiter(account.account_size) %>
        </p>
      </div>
      <div>
        <p class="text-sm text-secondary">Cash</p>
        <p class="text-2xl font-semibold text-primary">
          ₹<%= number_with_delimiter(account.cash_balance) %>
          <span class="text-sm text-secondary">(<%= account.cash_percentage %>%)</span>
        </p>
      </div>
      <div>
        <p class="text-sm text-secondary">Deployed</p>
        <p class="text-lg font-medium text-primary">
          ₹<%= number_with_delimiter(account.deployed_capital) %>
          (<%= account.deployed_percentage %>%)
        </p>
      </div>
      <div>
        <p class="text-sm text-secondary">Risk per Trade</p>
        <p class="text-lg font-medium text-primary"><%= account.risk_per_trade %>%</p>
      </div>
    </div>

    <div class="flex gap-4">
      <%= link_to "View Cash Ledger", settings_account_cash_ledger_path(account),
          class: "btn-primary-sm" %>
      <%= link_to "Manage Risk Settings", settings_account_risk_path(account),
          class: "btn-secondary-sm" %>
    </div>
  </div>
<% end %>
```

---

### Feature 2: Cash Ledger View

**User Story:**
> As a systematic trader, I want to track every deposit and withdrawal in my trading account, so I can accurately calculate returns and maintain precise performance records.

**Inspiration from Competitors:**

**Edgewonk Approach:** ✅ **Adopt This**
- Dedicated "Deposits & Withdrawals" tab in Settings
- Simple table: Date | Type | Amount | Balance After | Note
- Green button for new entries, click row to edit
- Negative amounts for withdrawals (e.g., -₹50,000)
- Warnings if deposits are missing or have wrong dates

**Zerodha Console Approach:** ✅ **Learn From This**
- Shows Payin/Payout in chart format
- Instant withdrawal feature (₹100 - ₹2,00,000 per day)
- Clear distinction between standard and instant withdrawals
- Timeline view of all fund movements

**TradeFlow Approach:** **Best of Both**
- Edgewonk's simplicity + Zerodha's visual timeline + Momentum trader context

**UI Layout:**

```
┌─────────────────────────────────────────────────────────────┐
│ Settings → Accounts → Personal Growth → Cash Ledger          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Account: Personal Growth (Zerodha)                          │
│  Current Cash Balance: ₹1,24,350                            │
│  Total Deposits: ₹5,00,000   Total Withdrawals: ₹75,000    │
│                                                               │
│  [+ Add Deposit]  [+ Add Withdrawal]  [Export CSV]          │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Cash Ledger (All Time)                              │   │
│  ├──────┬──────────┬──────────┬──────────┬───────────┤   │
│  │ Date │   Type   │  Amount  │ Balance  │   Note     │   │
│  ├──────┼──────────┼──────────┼──────────┼───────────┤   │
│  │ Mar 15│ Deposit │+₹1,00,000│ ₹1,24,350│ Salary Q1 │ ⋮ │
│  │ Feb 20│Withdrawal│ -₹50,000│   ₹24,350│ Tax payment│ ⋮ │
│  │ Jan 10│ Deposit │+₹2,00,000│   ₹74,350│Initial cap│ ⋮ │
│  │ Jan 01│ Deposit │+₹2,00,000│   ₹2,00,000│Opening bal│ ⋮ │
│  └──────┴──────────┴──────────┴──────────┴───────────┘   │
│                                                               │
│  Pagination: [< Prev]  Page 1 of 3  [Next >]                │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Features:**

1. **Add Deposit/Withdrawal Modal:**
```
┌─────────────────────────────────────────┐
│ Add Deposit to Personal Growth           │
├─────────────────────────────────────────┤
│                                           │
│ Date: [15/03/2025 ▼]                    │
│                                           │
│ Type: ◉ Deposit  ○ Withdrawal            │
│                                           │
│ Amount: [₹________]                      │
│                                           │
│ Note (optional):                         │
│ [_________________________________]      │
│                                           │
│ Balance After: ₹1,24,350 (calculated)   │
│                                           │
│         [Cancel]  [Add Transaction]      │
└─────────────────────────────────────────┘
```

2. **Validation Rules:**
   - Date cannot be in future
   - Withdrawal cannot exceed current cash balance
   - Amount must be positive (system auto-negates for withdrawals)
   - Warning if deposit date is before last trade date

3. **Auto-Calculations:**
   - Running balance updates automatically
   - System recalculates all "Balance After" when editing past entries
   - Performance metrics auto-adjust for time-weighted returns

**Technical Implementation:**

```ruby
# app/models/cash_transaction.rb
class CashTransaction < ApplicationRecord
  belongs_to :trading_account

  enum transaction_type: { deposit: 0, withdrawal: 1 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true
  validate :withdrawal_not_greater_than_balance

  scope :chronological, -> { order(transaction_date: :asc) }
  scope :recent_first, -> { order(transaction_date: :desc) }

  after_save :recalculate_balances
  after_destroy :recalculate_balances

  # Display amount with sign
  def signed_amount
    transaction_type == 'deposit' ? amount : -amount
  end

  # Calculate balance after this transaction
  def balance_after
    account = trading_account
    prior_balance = account.cash_transactions
                           .where('transaction_date < ?', transaction_date)
                           .sum('CASE WHEN transaction_type = 0 THEN amount ELSE -amount END')

    prior_balance + signed_amount
  end

  private

  def withdrawal_not_greater_than_balance
    return unless withdrawal?
    return if transaction_date.blank?

    balance_before = trading_account.cash_balance_at(transaction_date)
    if amount > balance_before
      errors.add(:amount, "withdrawal of ₹#{amount} exceeds available balance of ₹#{balance_before}")
    end
  end

  def recalculate_balances
    # Trigger account snapshot update
    trading_account.update_cash_balance_from_ledger
  end
end

# app/models/trading_account.rb (additions)
class TradingAccount < ApplicationRecord
  has_many :cash_transactions, dependent: :destroy

  def cash_balance_at(date)
    cash_transactions
      .where('transaction_date <= ?', date)
      .sum('CASE WHEN transaction_type = 0 THEN amount ELSE -amount END')
  end

  def total_deposits
    cash_transactions.deposit.sum(:amount)
  end

  def total_withdrawals
    cash_transactions.withdrawal.sum(:amount)
  end

  def update_cash_balance_from_ledger
    latest_balance = cash_balance_at(Date.today)

    # Update latest snapshot or create new one
    snapshot = account_snapshots.find_or_create_by(date: Date.today)
    snapshot.update(cash_balance: latest_balance)
  end
end
```

**Database Migration:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_cash_transactions.rb
class CreateCashTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :cash_transactions do |t|
      t.references :trading_account, null: false, foreign_key: true
      t.integer :transaction_type, null: false, default: 0  # 0: deposit, 1: withdrawal
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.date :transaction_date, null: false
      t.text :note
      t.decimal :balance_after, precision: 15, scale: 2  # Cached for performance

      t.timestamps
    end

    add_index :cash_transactions, [:trading_account_id, :transaction_date]
    add_index :cash_transactions, :transaction_date
  end
end
```

---

## Page 3: Risk Settings & Account Preferences

### Feature 3: Account-Specific Risk Management

**User Story:**
> As a momentum trader with multiple strategies, I want different risk settings for each account (Aggressive: 2.5%, Conservative: 1%), so I can maintain discipline appropriate to each account's purpose.

**Inspiration from Competitors:**

**Interactive Brokers Approach:** ✅ **Adopt This**
- Risk Navigator for real-time risk monitoring
- Account-level margin and risk limits
- Position-by-position risk analysis
- Portfolio heat map visualization

**TradingView Limitations:** ❌ **Improve Upon This**
- No global account risk settings
- Must set risk per trade via drawing tools
- No account-wide risk monitoring
- Requires manual template application

**Edgewonk Approach:** 🟡 **Partial Adoption**
- Global risk settings only (not per-account)
- Position sizing calculator based on account size
- R-multiple tracking

**TradeFlow Approach:** **Account-First Risk Controls**
- Per-account risk presets (overrides global defaults)
- Position sizing calculator integrated with cash ledger
- Real-time portfolio heat monitoring
- Momentum trading methodology alignment (Stage 2 entries, SEPA setups)

**UI Layout:**

```
┌─────────────────────────────────────────────────────────────┐
│ Settings → Accounts → Personal Growth → Risk Settings        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Account: Personal Growth                                    │
│  Current Account Size: ₹5,24,350                            │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Risk Per Trade                                        ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  Maximum Risk per Trade:  [2.0] %                      ║ │
│  ║                           = ₹10,487 per trade          ║ │
│  ║                                                         ║ │
│  ║  ℹ️  This is the maximum amount you're willing to      ║ │
│  ║     lose on a single trade if it hits your stop loss. ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Portfolio Risk Limits                                 ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  Maximum Portfolio Heat:  [8.0] %                      ║ │
│  ║  (Total risk across all open positions)               ║ │
│  ║                                                         ║ │
│  ║  Current Portfolio Heat: 5.2% ✅                       ║ │
│  ║  [████████░░] 5.2% / 8.0%                             ║ │
│  ║                                                         ║ │
│  ║  ⚠️  You have room for 1 more position at max risk    ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Position Sizing Method                                ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  ◉ Fixed % Risk (Recommended for Stage 2 breakouts)   ║ │
│  ║  ○ Fixed Dollar Amount                                ║ │
│  ║  ○ Kelly Criterion                                    ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Stop Loss Preferences                                 ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  Default Stop Loss Type:                              ║ │
│  ║  ◉ Percentage-based (e.g., 7% below entry)            ║ │
│  ║  ○ ATR-based (e.g., 2x ATR)                           ║ │
│  ║  ○ Support level (manual chart analysis)             ║ │
│  ║                                                         ║ │
│  ║  Default Stop Distance: [7.0] %                       ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  [Cancel]  [Save Risk Settings]                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Position Sizing Calculator (Integrated in Trade Entry):**

When entering a new trade, calculator appears:

```
┌─────────────────────────────────────────┐
│ Position Size Calculator                 │
├─────────────────────────────────────────┤
│                                           │
│ Account: Personal Growth                 │
│ Account Size: ₹5,24,350                 │
│ Max Risk/Trade: 2.0% = ₹10,487          │
│                                           │
│ Entry Price: ₹[850.00]                  │
│ Stop Loss:   ₹[790.00] (7% below)       │
│ Risk/Share:  ₹60.00                     │
│                                           │
│ ╔═══════════════════════════════════╗   │
│ ║ Recommended Position Size:        ║   │
│ ║                                     ║   │
│ ║   174 shares                       ║   │
│ ║   = ₹1,47,900 invested            ║   │
│ ║   = 28.2% of account               ║   │
│ ║                                     ║   │
│ ╚═══════════════════════════════════╝   │
│                                           │
│ Adjust quantity: [174] shares            │
│                                           │
│ Actual risk: ₹10,440 (2.0%) ✅          │
│                                           │
│         [Cancel]  [Use This Size]        │
└─────────────────────────────────────────┘
```

**Technical Implementation:**

```ruby
# app/models/risk_setting.rb
class RiskSetting < ApplicationRecord
  belongs_to :trading_account

  validates :max_risk_per_trade_percent, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :max_portfolio_heat_percent, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 20 }

  enum position_sizing_method: {
    fixed_percent_risk: 0,
    fixed_dollar: 1,
    kelly_criterion: 2
  }

  enum stop_loss_type: {
    percentage_based: 0,
    atr_based: 1,
    support_level: 2
  }

  # Calculate position size based on account size and risk
  def calculate_position_size(entry_price:, stop_loss:, account_size: nil)
    account_size ||= trading_account.account_size

    max_risk_amount = account_size * (max_risk_per_trade_percent / 100.0)
    risk_per_share = entry_price - stop_loss

    return 0 if risk_per_share <= 0

    shares = (max_risk_amount / risk_per_share).floor

    {
      shares: shares,
      invested_amount: shares * entry_price,
      max_risk_amount: max_risk_amount,
      actual_risk: shares * risk_per_share,
      account_percentage: (shares * entry_price / account_size * 100).round(2)
    }
  end

  # Check if new position would exceed portfolio heat
  def within_portfolio_heat_limit?(new_position_risk)
    current_heat = trading_account.current_portfolio_heat_percent
    new_heat = current_heat + (new_position_risk / trading_account.account_size * 100)

    new_heat <= max_portfolio_heat_percent
  end
end

# app/models/trading_account.rb (additions)
class TradingAccount < ApplicationRecord
  has_one :risk_setting, dependent: :destroy

  after_create :create_default_risk_setting

  def current_portfolio_heat_percent
    total_risk = positions.active.sum do |position|
      position.risk_amount  # Position model calculates: (entry_price - stop_loss) * quantity
    end

    return 0 if account_size.zero?
    (total_risk / account_size * 100).round(2)
  end

  def positions_available_at_max_risk
    return 0 if account_size.zero?

    available_risk = account_size * (risk_setting.max_portfolio_heat_percent / 100.0)
    current_risk = positions.active.sum(&:risk_amount)
    remaining_risk = available_risk - current_risk

    max_risk_per_position = account_size * (risk_setting.max_risk_per_trade_percent / 100.0)

    (remaining_risk / max_risk_per_position).floor
  end

  private

  def create_default_risk_setting
    RiskSetting.create!(
      trading_account: self,
      max_risk_per_trade_percent: 2.0,  # Conservative default
      max_portfolio_heat_percent: 8.0,
      position_sizing_method: :fixed_percent_risk,
      stop_loss_type: :percentage_based,
      default_stop_distance_percent: 7.0
    )
  end
end
```

---

## Page 4: Account Edit & Configuration

### Feature 4: Account Details & Connection Management

**User Story:**
> As a trader, I want to edit my account name, change account type, and manage my Zerodha API connection, so I can keep my account information current and resolve connection issues.

**UI Layout:**

```
┌─────────────────────────────────────────────────────────────┐
│ Settings → Accounts → Edit Account: Personal Growth          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Account Information                                   ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  Account Name: [Personal Growth_______________]        ║ │
│  ║                                                         ║ │
│  ║  Account Type: [Growth ▼]                              ║ │
│  ║                 Options: Growth, Retirement,           ║ │
│  ║                          Aggressive, Conservative,     ║ │
│  ║                          Options Trading, Family       ║ │
│  ║                                                         ║ │
│  ║  Description (optional):                               ║ │
│  ║  [Main trading account for Stage 2 breakouts]         ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Broker Connection                                     ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  Broker: Zerodha                                       ║ │
│  ║  Connection Status: 🟢 Connected                       ║ │
│  ║  Last Synced: 2 hours ago                             ║ │
│  ║                                                         ║ │
│  ║  Zerodha User ID: AB1234                              ║ │
│  ║  API Key: ••••••••••••5678                            ║ │
│  ║                                                         ║ │
│  ║  [Reconnect API]  [Test Connection]                   ║ │
│  ║                                                         ║ │
│  ║  ⚠️  If connection fails, click Reconnect to         ║ │
│  ║     re-authorize via Zerodha Kite Connect.           ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Sync Settings                                         ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  ☑ Auto-sync trades daily at 4:00 PM                  ║ │
│  ║  ☑ Auto-sync positions every 15 minutes (market hrs) ║ │
│  ║  ☑ Sync account value and cash balance daily         ║ │
│  ║                                                         ║ │
│  ║  Last Full Sync: Today at 3:45 PM                     ║ │
│  ║  Next Scheduled Sync: Today at 4:00 PM                ║ │
│  ║                                                         ║ │
│  ║  [Sync Now]                                            ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗ │
│  ║ Danger Zone                                           ║ │
│  ╠═══════════════════════════════════════════════════════╣ │
│  ║                                                         ║ │
│  ║  [Archive Account]                                     ║ │
│  ║  Keeps all trade history but hides from active list   ║ │
│  ║                                                         ║ │
│  ║  [Delete Account]                                      ║ │
│  ║  ⚠️  Permanently deletes ALL trades, positions, and   ║ │
│  ║     cash ledger entries. This cannot be undone.       ║ │
│  ║                                                         ║ │
│  ╚═══════════════════════════════════════════════════════╝ │
│                                                               │
│  [Cancel]  [Save Changes]                                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Account Type Presets:**

Each account type comes with recommended risk settings:

| Account Type | Default Risk/Trade | Default Portfolio Heat | Typical Use Case |
|--------------|-------------------|----------------------|------------------|
| Aggressive   | 2.5%              | 10%                  | Active momentum trading |
| Growth       | 2.0%              | 8%                   | Standard growth portfolio |
| Conservative | 1.0%              | 5%                   | Capital preservation |
| Retirement   | 0.5%              | 3%                   | Long-term retirement |
| Options      | 3.0%              | 12%                  | Options strategies |
| Family       | 1.5%              | 6%                   | Family wealth management |

**Technical Implementation:**

```ruby
# app/controllers/settings/accounts_controller.rb
class Settings::AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, except: [:index, :new, :create]

  def edit
    @account_types = TradingAccount::ACCOUNT_TYPES
  end

  def update
    if @account.update(account_params)
      flash[:success] = "Account updated successfully"
      redirect_to settings_accounts_path
    else
      render :edit
    end
  end

  def reconnect_api
    # Redirect to Zerodha OAuth flow
    redirect_to zerodha_auth_url(account_id: @account.id), allow_other_host: true
  end

  def test_connection
    result = ZerodhaApiService.new(@account).test_connection

    if result[:success]
      flash[:success] = "Connection successful! Last synced: #{result[:last_sync]}"
    else
      flash[:error] = "Connection failed: #{result[:error]}"
    end

    redirect_to edit_settings_account_path(@account)
  end

  def sync_now
    SyncAccountJob.perform_later(@account.id)
    flash[:success] = "Sync initiated. Check back in a few minutes."
    redirect_to settings_account_path(@account)
  end

  private

  def set_account
    @account = current_user.trading_accounts.find(params[:id])
  end

  def account_params
    params.require(:trading_account).permit(
      :account_name,
      :account_type,
      :description,
      :auto_sync_trades,
      :auto_sync_positions,
      :auto_sync_account_value
    )
  end
end

# app/models/trading_account.rb (additions)
class TradingAccount < ApplicationRecord
  ACCOUNT_TYPES = {
    'aggressive' => { risk_per_trade: 2.5, portfolio_heat: 10.0 },
    'growth' => { risk_per_trade: 2.0, portfolio_heat: 8.0 },
    'conservative' => { risk_per_trade: 1.0, portfolio_heat: 5.0 },
    'retirement' => { risk_per_trade: 0.5, portfolio_heat: 3.0 },
    'options' => { risk_per_trade: 3.0, portfolio_heat: 12.0 },
    'family' => { risk_per_trade: 1.5, portfolio_heat: 6.0 }
  }.freeze

  enum account_type: ACCOUNT_TYPES.keys.map(&:to_sym)

  def connection_status_class
    case api_connection_status
    when 'connected' then 'text-green-600'
    when 'disconnected' then 'text-red-600'
    else 'text-yellow-600'
    end
  end

  def last_synced_humanized
    return 'Never' unless last_synced_at

    time_ago_in_words(last_synced_at) + ' ago'
  end
end
```

---

## Page 5: Implementation Roadmap & Technical Architecture

### Development Phases

**Phase 1: Foundation (Week 1)**
- [ ] Create `cash_transactions` table migration
- [ ] Create `CashTransaction` model with validations
- [ ] Create `risk_settings` table migration
- [ ] Create `RiskSetting` model with calculations
- [ ] Add account-level methods: `cash_balance_at`, `total_deposits`, `total_withdrawals`
- [ ] Create Settings::AccountsController with index/show/edit actions

**Phase 2: Cash Ledger (Week 2)**
- [ ] Build cash ledger UI (table + pagination)
- [ ] Create deposit/withdrawal modal forms
- [ ] Implement running balance calculations
- [ ] Add validation warnings (future dates, over-withdrawals)
- [ ] Build CSV export for cash transactions
- [ ] Write tests for cash transaction logic

**Phase 3: Risk Settings (Week 3)**
- [ ] Build risk settings form UI
- [ ] Implement position sizing calculator
- [ ] Create portfolio heat monitoring
- [ ] Add risk warnings in trade entry flow
- [ ] Integrate risk calculator with trade entry modal
- [ ] Write tests for position sizing calculations

**Phase 4: Account Management (Week 4)**
- [ ] Build account edit form
- [ ] Implement account type presets
- [ ] Add API reconnection flow
- [ ] Create sync now functionality
- [ ] Build account archival feature
- [ ] Add account deletion with confirmations

### Database Schema

```sql
-- Cash Transactions Table
CREATE TABLE cash_transactions (
  id BIGSERIAL PRIMARY KEY,
  trading_account_id BIGINT NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
  transaction_type INTEGER NOT NULL DEFAULT 0,  -- 0: deposit, 1: withdrawal
  amount DECIMAL(15,2) NOT NULL,
  transaction_date DATE NOT NULL,
  note TEXT,
  balance_after DECIMAL(15,2),  -- Cached for performance
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX index_cash_txns_on_account_and_date
  ON cash_transactions(trading_account_id, transaction_date);
CREATE INDEX index_cash_txns_on_date
  ON cash_transactions(transaction_date);

-- Risk Settings Table
CREATE TABLE risk_settings (
  id BIGSERIAL PRIMARY KEY,
  trading_account_id BIGINT NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
  max_risk_per_trade_percent DECIMAL(5,2) NOT NULL DEFAULT 2.0,
  max_portfolio_heat_percent DECIMAL(5,2) NOT NULL DEFAULT 8.0,
  position_sizing_method INTEGER NOT NULL DEFAULT 0,  -- 0: fixed_percent, 1: fixed_dollar, 2: kelly
  stop_loss_type INTEGER NOT NULL DEFAULT 0,  -- 0: percentage, 1: atr, 2: support
  default_stop_distance_percent DECIMAL(5,2) DEFAULT 7.0,
  default_stop_distance_atr_multiple DECIMAL(3,1) DEFAULT 2.0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX index_risk_settings_on_trading_account
  ON risk_settings(trading_account_id);

-- Trading Accounts Table (additions)
ALTER TABLE trading_accounts
  ADD COLUMN account_type VARCHAR(50) DEFAULT 'growth',
  ADD COLUMN description TEXT,
  ADD COLUMN auto_sync_trades BOOLEAN DEFAULT TRUE,
  ADD COLUMN auto_sync_positions BOOLEAN DEFAULT TRUE,
  ADD COLUMN auto_sync_account_value BOOLEAN DEFAULT TRUE,
  ADD COLUMN last_synced_at TIMESTAMP,
  ADD COLUMN api_connection_status VARCHAR(20) DEFAULT 'disconnected';
```

### Routes Configuration

```ruby
# config/routes.rb
namespace :settings do
  resources :accounts do
    member do
      get :cash_ledger
      post :add_cash_transaction
      patch :edit_cash_transaction
      delete :delete_cash_transaction

      get :risk_settings
      patch :update_risk_settings

      post :reconnect_api
      post :test_connection
      post :sync_now

      post :archive
      delete :destroy_with_confirmation
    end

    resources :cash_transactions, only: [:index, :create, :update, :destroy]
  end
end

# Generates routes:
# GET    /settings/accounts
# GET    /settings/accounts/:id
# GET    /settings/accounts/:id/edit
# PATCH  /settings/accounts/:id
# GET    /settings/accounts/:id/cash_ledger
# POST   /settings/accounts/:id/add_cash_transaction
# GET    /settings/accounts/:id/risk_settings
# PATCH  /settings/accounts/:id/update_risk_settings
# POST   /settings/accounts/:id/reconnect_api
# POST   /settings/accounts/:id/test_connection
# POST   /settings/accounts/:id/sync_now
```

### Performance Optimizations

**1. Cached Balance Calculations:**
```ruby
# Store balance_after in cash_transactions table to avoid recalculating
# Update only when transactions before current date change

def recalculate_balances_from(date)
  transactions = trading_account.cash_transactions
                                .where('transaction_date >= ?', date)
                                .chronological

  running_balance = trading_account.cash_balance_at(date - 1.day)

  transactions.each do |txn|
    running_balance += txn.signed_amount
    txn.update_column(:balance_after, running_balance)
  end
end
```

**2. Eager Loading:**
```ruby
# In AccountsController
def index
  @trading_accounts = current_user.trading_accounts
                                  .includes(:risk_setting, :account_snapshots, :positions)
                                  .order(created_at: :desc)
end
```

**3. Background Jobs:**
```ruby
# Sync accounts asynchronously
class SyncAccountJob < ApplicationJob
  queue_as :default

  def perform(trading_account_id)
    account = TradingAccount.find(trading_account_id)
    ZerodhaApiService.new(account).sync_all
    account.update(last_synced_at: Time.current)
  end
end
```

### Testing Strategy

**Model Tests:**
```ruby
# test/models/cash_transaction_test.rb
test "deposit increases balance" do
  account = trading_accounts(:personal)
  initial_balance = account.cash_balance

  CashTransaction.create!(
    trading_account: account,
    transaction_type: :deposit,
    amount: 10000,
    transaction_date: Date.today
  )

  assert_equal initial_balance + 10000, account.reload.cash_balance
end

test "withdrawal cannot exceed balance" do
  account = trading_accounts(:personal)
  account.cash_transactions.create!(
    transaction_type: :deposit,
    amount: 5000,
    transaction_date: Date.today
  )

  txn = account.cash_transactions.build(
    transaction_type: :withdrawal,
    amount: 10000,
    transaction_date: Date.today
  )

  assert_not txn.valid?
  assert_includes txn.errors[:amount], /exceeds available balance/
end

# test/models/risk_setting_test.rb
test "calculate_position_size returns correct shares" do
  risk_setting = risk_settings(:aggressive)
  risk_setting.update(max_risk_per_trade_percent: 2.0)

  result = risk_setting.calculate_position_size(
    entry_price: 100,
    stop_loss: 93,
    account_size: 100000
  )

  # Max risk: 100000 * 2% = 2000
  # Risk per share: 100 - 93 = 7
  # Shares: 2000 / 7 = 285 (floor)

  assert_equal 285, result[:shares]
  assert_equal 28500, result[:invested_amount]
  assert_equal 2000, result[:max_risk_amount]
end
```

### Success Metrics

**User Adoption:**
- 80%+ of multi-account users access Accounts page within first week
- 60%+ add at least one manual cash transaction
- 50%+ customize risk settings from defaults

**Feature Usage:**
- Average 3.2 cash transactions per account per month
- 75% of trades use position size calculator
- 40% of users modify risk settings at least once

**Data Quality:**
- 90%+ cash ledger balance accuracy (matches broker statements)
- 95%+ of accounts have risk settings configured
- <5% cash transaction errors or deletions

---

## Summary & Next Steps

### What This Delivers

✅ **Insight ─────────────────────────────────────**

**Business Value:**
1. **Multi-Account Discipline:** Traders can maintain different strategies across accounts without mental overhead
2. **Performance Accuracy:** Cash ledger ensures returns calculations account for deposits/withdrawals
3. **Risk Automation:** Position sizing calculator eliminates manual math errors and enforces discipline

**Technical Excellence:**
1. **Scalable Architecture:** JSONB for preferences, normalized cash transactions, cached calculations
2. **Momentum Trading Focus:** Risk presets aligned with Stage Analysis and SEPA methodologies
3. **Indian Market UX:** ₹ formatting, tax-aware reporting, Zerodha-first integration

**Competitive Advantage:**
- Only momentum trading journal with account-level risk management
- Combines Edgewonk's simplicity with Interactive Brokers' sophistication
- Purpose-built for Indian traders managing multiple strategies

**─────────────────────────────────────────────────**

### Recommended Priority

1. **Phase 1 + 2:** Cash Ledger (Weeks 1-2) - Core financial tracking
2. **Phase 3:** Risk Settings (Week 3) - Position sizing automation
3. **Phase 4:** Account Management (Week 4) - Polish and conveniences

### Ready to Build?

This specification provides everything needed to implement Settings → Accounts:
- Complete UI wireframes
- Database schema
- Model implementations
- Controller actions
- Test scenarios
- Performance optimizations

**Approve this spec and I'll begin implementation starting with Phase 1.**
