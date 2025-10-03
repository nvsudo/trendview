# Implementation Summary - Account Size & UI Preferences

## ✅ Completed: Account Size Refactor

### What Changed
**Before:** Dashboard showed "Total Value" from stale snapshots
**After:** Shows "Account Size" calculated live from positions + cash

### Files Modified

#### 1. User Model (`app/models/user.rb`)
- ✅ Renamed `total_portfolio_value` → `total_account_size`
- ✅ Added `total_cash_balance` method
- ✅ Updated `total_deployed_percentage` to use `total_account_size`
- ✅ Added UI preferences associations and helper methods

#### 2. TradingAccount Model (`app/models/trading_account.rb`)
- ✅ Renamed `current_portfolio_value` → `account_size`
- ✅ Added `open_positions_value` method
- ✅ Added `cash_balance` method (from latest snapshot)
- ✅ Updated `deployed_percentage` calculation

#### 3. Dashboard Controller (`app/controllers/dashboard_controller.rb`)
- ✅ Updated `calculate_portfolio_stats` - uses `total_account_size`
- ✅ Updated `calculate_enhanced_portfolio_stats`:
  - Uses `total_account_size` instead of `total_portfolio_value`
  - Added `total_cash` field
  - Fixed `cash_percentage` calculation

#### 4. Dashboard View (`app/views/dashboard/index.html.erb`)
- ✅ Card 1: "Total Value" → "Account Size"
- ✅ Card 1: Shows `@portfolio_stats[:total_account_size]`
- ✅ Card 2: Shows `@portfolio_stats[:total_cash]` (actual value, not calculated)
- ✅ Card 2: Shows cash percentage of account
- ✅ Card 3 & 4: Use `total_account_size` for percentage calculations

### How It Works Now

```ruby
# Account Size = Open Positions + Cash
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

### Dashboard Cards
1. **Account Size** = ₹1,000,000 (positions ₹850k + cash ₹150k)
2. **Cash** = ₹150,000 (15% of account) - subset of Account Size
3. **P&L Today** = ₹12,450
4. **Net P&L** = ₹45,000

---

## ✅ Completed: UI Preferences System

### What Was Built
A complete, extensible UI preferences system using PostgreSQL JSONB for flexibility.

### Database

#### Migration: `20251003075858_create_user_ui_preferences.rb`
```ruby
create_table :user_ui_preferences do |t|
  t.references :user, null: false, foreign_key: true
  t.string :preference_category, null: false  # e.g., "positions_table"
  t.string :preference_key, null: false       # e.g., "columns"
  t.jsonb :preference_value, default: {}, null: false
  t.text :description
  t.timestamps
end

# Indexes
add_index :user_ui_preferences,
  [:user_id, :preference_category, :preference_key],
  unique: true

add_index :user_ui_preferences, :preference_value, using: :gin
```

**Status:** ✅ Migrated successfully

### Model

#### UserUiPreference (`app/models/user_ui_preference.rb`)
- ✅ Belongs to User
- ✅ Validations for all required fields
- ✅ Scopes: `for_category`, `for_key`
- ✅ Class methods:
  - `get(user, category, key, default)` - Get preference or default
  - `set(user, category, key, value, description)` - Save preference
  - `update_nested(user, category, key, path, value)` - Update nested JSONB value

### Controller

#### PreferencesController (`app/controllers/preferences_controller.rb`)
- ✅ GET `/preferences/:category/:key` - Fetch preference
- ✅ PUT `/preferences/:category/:key` - Update entire preference
- ✅ PATCH `/preferences/:category/:key/nested` - Update nested value
- ✅ Uses default constants as fallbacks

### User Model Integration

#### Added to User Model:
```ruby
# Association
has_many :ui_preferences, class_name: 'UserUiPreference', dependent: :destroy

# Helper methods
def get_preference(category, key, default = {})
  UserUiPreference.get(self, category, key, default)
end

def set_preference(category, key, value)
  UserUiPreference.set(self, category, key, value)
end

# Specific getters
def position_columns_preference
  get_preference('positions_table', 'columns', DEFAULT_POSITION_COLUMNS)
end
```

### Preference Defaults

#### Created: `config/initializers/preference_defaults.rb`

**DEFAULT_POSITION_COLUMNS:**
```ruby
{
  "symbol" => { "visible" => true, "order" => 1, "width" => 120 },
  "quantity" => { "visible" => true, "order" => 2, "width" => 80 },
  "ltp" => { "visible" => true, "order" => 3, "width" => 100 },
  "pnl_amount" => { "visible" => true, "order" => 4, "width" => 100 },
  "pnl_percent" => { "visible" => true, "order" => 5, "width" => 80 }
}
```

**AVAILABLE_POSITION_COLUMNS:**
```ruby
[
  { key: "symbol", label: "Symbol", always_visible: true },
  { key: "weight_percent", label: "Weight %", always_visible: false },
  { key: "quantity", label: "Qty", always_visible: false },
  { key: "ltp", label: "LTP", always_visible: false },
  { key: "invested", label: "Invested", always_visible: false },
  { key: "current_value", label: "Current", always_visible: false },
  { key: "pnl_amount", label: "P&L", always_visible: false },
  { key: "pnl_percent", label: "P&L %", always_visible: false },
  { key: "sentiment_tag", label: "Tag", always_visible: false }
]
```

**DEFAULT_DASHBOARD_LAYOUT** (for future use)
**DEFAULT_DISPLAY_FORMATS** (for future use)

### Routes

#### Added to `config/routes.rb`:
```ruby
resources :preferences, only: [] do
  collection do
    get ':category/:key', action: :show, as: :get
    put ':category/:key', action: :update, as: :set
    patch ':category/:key/nested', action: :update_nested, as: :update_nested
  end
end
```

**Available Endpoints:**
- `GET /preferences/positions_table/columns` → Get columns preference
- `PUT /preferences/positions_table/columns` → Update columns preference
- `PATCH /preferences/positions_table/columns/nested` → Update single column setting

### Position Model Enhancement

#### Added: `portfolio_weight_percent` method
```ruby
def portfolio_weight_percent(total_portfolio_value)
  return 0 if total_portfolio_value.zero?
  (current_value / total_portfolio_value * 100).round(1)
end
```

### UI Updates

#### Holdings Section (`app/views/dashboard/_holdings_section.html.erb`)
- ✅ Added gear icon (⚙️) for column customization
- ✅ Positioned next to "Add Position" button
- ✅ Tooltip: "Customize columns"

---

## 🚀 How to Use

### Get User's Preference
```ruby
# In controller or view
columns = current_user.position_columns_preference
# Returns JSONB hash or DEFAULT_POSITION_COLUMNS
```

### Set User's Preference
```ruby
# Update entire preference
current_user.set_preference(
  'positions_table',
  'columns',
  {
    "symbol" => { "visible" => true, "order" => 1 },
    "weight_percent" => { "visible" => true, "order" => 2 }
  }
)

# Or via API
PUT /preferences/positions_table/columns
{
  "value": {
    "symbol": { "visible": true, "order": 1 },
    "weight_percent": { "visible": true, "order": 2 }
  }
}
```

### Update Single Nested Value
```ruby
# Toggle one column's visibility
UserUiPreference.update_nested(
  current_user,
  'positions_table',
  'columns',
  'symbol.visible',
  false
)

# Or via API
PATCH /preferences/positions_table/columns/nested
{
  "path": "symbol.visible",
  "value": false
}
```

---

## 📊 Testing Status

### Syntax Check
✅ All files pass Ruby syntax validation:
- `app/models/user_ui_preference.rb` - OK
- `app/controllers/preferences_controller.rb` - OK
- `app/models/user.rb` - OK
- `app/models/trading_account.rb` - OK
- `app/models/position.rb` - OK

### Database Migration
✅ Migration ran successfully:
- Table `user_ui_preferences` created
- Unique index on `user_id + category + key`
- GIN index on `preference_value` (JSONB)

### Server Status
✅ Rails server boots successfully (tested with timeout command)

---

## 🎯 What's Ready

### ✅ Account Size Feature
1. Live calculation from positions + cash
2. Card 1 shows total account size
3. Card 2 shows cash (subset of account size)
4. Accurate percentage calculations

### ✅ UI Preferences Infrastructure
1. Database table with JSONB storage
2. Model with get/set/update methods
3. Controller with REST API endpoints
4. User associations and helpers
5. Default constants for fallbacks
6. Routes configured

### ✅ Position Enhancements
1. `portfolio_weight_percent` method added
2. Gear icon in holdings section
3. Ready for column customization UI

---

## 🔮 Next Steps (Not Implemented)

### Column Customization UI (Frontend)
- [ ] Stimulus controller for column toggle
- [ ] Modal/dropdown for column settings
- [ ] Drag-and-drop column reordering
- [ ] AJAX save to preferences API
- [ ] Real-time table update

### Additional Preferences
- [ ] Dashboard layout customization
- [ ] Chart defaults (timeframe, indicators)
- [ ] Display formats (number/date formats)
- [ ] Trades table columns
- [ ] Watchlist table columns

### Feature Completions (from design-specs.md)
- [ ] Buy/Sell sentiment tags (needs decision on logic)
- [ ] Enhanced market feed (social features)
- [ ] Watchlist enhancement (separate table)

---

## 📝 Files Created/Modified

### Created:
1. `db/migrate/20251003075858_create_user_ui_preferences.rb`
2. `app/models/user_ui_preference.rb`
3. `app/controllers/preferences_controller.rb`
4. `config/initializers/preference_defaults.rb`

### Modified:
1. `app/models/user.rb` - Account size methods + UI prefs
2. `app/models/trading_account.rb` - Account size calculation
3. `app/models/position.rb` - Portfolio weight method
4. `app/controllers/dashboard_controller.rb` - Stats calculation
5. `app/views/dashboard/index.html.erb` - Card updates
6. `app/views/dashboard/_holdings_section.html.erb` - Gear icon
7. `config/routes.rb` - Preferences routes

---

## 🎉 Summary

**Account Size Refactor:** ✅ Complete
- Changed from stale snapshots to live calculation
- Card labels updated, data flow corrected
- Cash properly shown as subset of account size

**UI Preferences System:** ✅ Complete
- Full JSONB-based extensible system
- REST API for preferences CRUD
- Default constants for fallbacks
- Ready for frontend integration

**Time Invested:** ~2 hours
**Next Action:** Build frontend column customization UI using the preferences API
