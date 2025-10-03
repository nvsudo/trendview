# Account Size Refactor - Correct Calculation

## Problem Statement

**Current:** Dashboard shows "Total Value" calculated from stale snapshots
**Correct:** Should show "Account Size" = Open Positions + Cash (live calculation)

---

## What Changed

### Terminology
- **Old:** "Total Portfolio Value"
- **New:** "Account Size"
- **Why:** More accurate - represents total capital (deployed + available)

### Calculation Method
- **Old:** Sum of `account_snapshots.total_value` (stale)
- **New:** Sum of `(open_positions_value + cash_balance)` (live)

### Dashboard Cards
1. **Account Size** = Open Positions + Cash
2. **Cash** = Subset of Account Size (available capital)
3. **P&L Today** = Day's profit/loss
4. **Net P&L** = Total unrealized P&L

---

## Implementation Checklist

### 1. User Model (`app/models/user.rb`)

**Changes:**
```ruby
# Rename existing method
def total_account_size  # was: total_portfolio_value
  trading_accounts.sum(&:account_size)
end

# Add new method for total cash
def total_cash_balance
  trading_accounts.sum(&:cash_balance)
end
```

**Impact:**
- [ ] Rename `total_portfolio_value` → `total_account_size`
- [ ] Add `total_cash_balance` method
- [ ] Update any other code calling `total_portfolio_value`

---

### 2. TradingAccount Model (`app/models/trading_account.rb`)

**Changes:**
```ruby
# Rename and recalculate
def account_size  # was: current_portfolio_value
  open_positions_value + cash_balance
end

# Add helper method for positions value
def open_positions_value
  positions.active.sum(&:current_value)
end

# Cash balance from latest snapshot
def cash_balance
  account_snapshots.recent.first&.cash_balance || 0
end
```

**Impact:**
- [ ] Rename `current_portfolio_value` → `account_size`
- [ ] Add `open_positions_value` method
- [ ] Ensure `cash_balance` method exists (may already exist)
- [ ] Update any other code calling `current_portfolio_value`

---

### 3. Dashboard Controller (`app/controllers/dashboard_controller.rb`)

**Changes:**
```ruby
def calculate_enhanced_portfolio_stats
  total_account_size = current_user.total_account_size  # Renamed
  total_cash = current_user.total_cash_balance          # New
  deployed_percentage = current_user.total_deployed_percentage
  daily_pnl = calculate_daily_pnl
  net_pnl = calculate_net_pnl

  {
    total_account_size: total_account_size,  # Renamed key
    total_cash: total_cash,                   # New key
    cash_percentage: total_account_size.zero? ? 0 : (total_cash / total_account_size * 100).round(2),
    daily_pnl: daily_pnl,
    net_pnl: net_pnl,
    deployed_percentage: deployed_percentage
  }
end

def calculate_portfolio_stats
  {
    total_account_size: current_user.total_account_size,  # Renamed
    deployed_percentage: current_user.total_deployed_percentage,
    total_trades: current_user.trades.count,
    winning_trades: current_user.trades.profitable.count,
    losing_trades: current_user.trades.losing.count
  }
end
```

**Impact:**
- [ ] Update `calculate_enhanced_portfolio_stats` method
- [ ] Update `calculate_portfolio_stats` method
- [ ] Change hash keys: `total_value` → `total_account_size`
- [ ] Add `total_cash` to stats hash
- [ ] Update `cash_percentage` calculation

---

### 4. Dashboard View (`app/views/dashboard/index.html.erb`)

**Changes:**
```erb
<!-- Card 1: Account Size (was: Total Value) -->
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

<!-- Card 2: Cash (was using cash_percentage) -->
<div class="bg-container rounded-2xl border border-border p-6">
  <div class="text-sm text-secondary mb-1">Cash</div>
  <div class="text-3xl font-semibold text-primary mb-2">
    ₹<%= number_with_delimiter(@portfolio_stats[:total_cash]) %>
  </div>
  <div class="text-sm text-secondary">
    <%= @portfolio_stats[:cash_percentage].round(2) %>% of account
  </div>
</div>

<!-- Card 3: P&L Today (update denominator) -->
<div class="bg-container rounded-2xl border border-border p-6">
  <div class="text-sm text-secondary mb-1">P&L Today</div>
  <div class="text-3xl font-semibold text-primary mb-2">
    ₹<%= number_with_delimiter(@portfolio_stats[:daily_pnl]) %>
  </div>
  <div class="text-sm <%= @portfolio_stats[:daily_pnl] >= 0 ? 'text-green-600' : 'text-red-600' %>">
    <%= format_percentage_change(@portfolio_stats[:daily_pnl], @portfolio_stats[:total_account_size]) %>
  </div>
</div>

<!-- Card 4: Net P&L (update denominator) -->
<div class="bg-container rounded-2xl border border-border p-6">
  <div class="text-sm text-secondary mb-1">Net P&L</div>
  <div class="text-3xl font-semibold text-primary mb-2">
    ₹<%= number_with_delimiter(@portfolio_stats[:net_pnl]) %>
  </div>
  <div class="text-sm <%= @portfolio_stats[:net_pnl] >= 0 ? 'text-green-600' : 'text-red-600' %>">
    <%= format_percentage_change(@portfolio_stats[:net_pnl], @portfolio_stats[:total_account_size]) %>
  </div>
</div>
```

**Impact:**
- [ ] Update Card 1: "Total Value" → "Account Size"
- [ ] Update Card 1: `@portfolio_stats[:total_value]` → `@portfolio_stats[:total_account_size]`
- [ ] Update Card 2: Show `@portfolio_stats[:total_cash]` instead of calculated cash
- [ ] Update Card 2: Show `@portfolio_stats[:cash_percentage]` below
- [ ] Update Card 3 & 4: Use `total_account_size` for percentage calculations

---

### 5. Other Files to Update

**Search for usages of:**
- `total_portfolio_value` → Replace with `total_account_size`
- `current_portfolio_value` → Replace with `account_size`
- `@portfolio_stats[:total_value]` → Replace with `@portfolio_stats[:total_account_size]`

**Files to check:**
- [ ] `app/views/dashboard/analytics.html.erb`
- [ ] `app/views/dashboard/portfolio.html.erb`
- [ ] `app/helpers/dashboard_helper.rb` (if exists)
- [ ] `app/models/user.rb` (other methods using total_portfolio_value)
- [ ] `test/models/user_test.rb`
- [ ] `test/controllers/dashboard_controller_test.rb`
- [ ] Any background jobs or rake tasks

---

## Testing Plan

### 1. Unit Tests (Models)

```ruby
# test/models/user_test.rb
test "total_account_size sums all account sizes" do
  user = users(:trader)

  # Mock account sizes
  account1 = user.trading_accounts.first
  account1.positions.create!(...)  # Create positions
  # ... set up cash balance in snapshot

  assert_equal expected_total, user.total_account_size
end

test "total_cash_balance sums all cash balances" do
  user = users(:trader)
  # ... setup
  assert_equal expected_cash, user.total_cash_balance
end
```

```ruby
# test/models/trading_account_test.rb
test "account_size equals positions plus cash" do
  account = trading_accounts(:personal)

  # Create positions worth ₹100,000
  create_positions_worth(account, 100_000)

  # Set cash balance to ₹50,000
  create_snapshot_with_cash(account, 50_000)

  assert_equal 150_000, account.account_size
end

test "open_positions_value sums active positions only" do
  account = trading_accounts(:personal)

  # Create 2 active positions + 1 closed
  create_active_position(account, 50_000)
  create_active_position(account, 30_000)
  create_closed_position(account, 20_000)  # Should not count

  assert_equal 80_000, account.open_positions_value
end
```

### 2. Controller Tests

```ruby
# test/controllers/dashboard_controller_test.rb
test "dashboard stats include total_account_size and total_cash" do
  sign_in users(:trader)
  get dashboard_index_url

  assert_response :success
  assert assigns(:portfolio_stats)[:total_account_size].present?
  assert assigns(:portfolio_stats)[:total_cash].present?
  assert assigns(:portfolio_stats)[:cash_percentage].present?
end
```

### 3. Integration Test (End-to-End)

```ruby
# test/integration/dashboard_stats_test.rb
test "dashboard displays correct account size and cash" do
  # Setup user with positions and cash
  user = create_user_with_portfolio(
    positions_value: 450_000,
    cash_balance: 50_000
  )

  sign_in user
  get dashboard_index_url

  # Check Card 1: Account Size
  assert_select "div", text: /Account Size/
  assert_select "div", text: /₹500,000/  # 450k + 50k

  # Check Card 2: Cash (subset)
  assert_select "div", text: /Cash/
  assert_select "div", text: /₹50,000/
  assert_select "div", text: /10\.0% of account/  # 50k / 500k
end
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Manual testing in development
- [ ] Manual testing in staging (if available)
- [ ] Database has `cash_balance` in `account_snapshots` table
- [ ] Positions have valid `current_value` calculations

### Deployment
- [ ] Deploy code to production
- [ ] Monitor error logs for any issues
- [ ] Verify dashboard displays correctly
- [ ] Check that calculations are accurate

### Post-Deployment Verification
- [ ] Account Size card shows (positions + cash)
- [ ] Cash card shows correct cash amount
- [ ] Cash percentage is correct (cash / account size * 100)
- [ ] P&L percentages use account size as denominator
- [ ] No errors in production logs

---

## Rollback Plan

If issues arise:

1. **Quick Fix:** Revert to snapshot-based calculation
   ```ruby
   def total_account_size
     trading_accounts.sum { |a| a.account_snapshots.recent.first&.total_value || 0 }
   end
   ```

2. **Full Rollback:** Restore previous method names
   - `total_account_size` → `total_portfolio_value`
   - `account_size` → `current_portfolio_value`
   - Revert view changes

3. **Data Issue:** If `cash_balance` is missing in snapshots
   - Add default cash calculation
   - Create migration to populate missing cash values

---

## Benefits of This Change

### 1. Accuracy
- **Live data** from open positions (not stale snapshots)
- **Real-time** account size updates as positions change
- **Correct cash** tracking (subset of account size)

### 2. Clarity
- **Better naming** ("Account Size" vs. "Portfolio Value")
- **Clear relationship** between cards (Cash ⊂ Account Size)
- **Trader-friendly** terminology (standard in trading platforms)

### 3. Performance
- **Efficient calculation** (one query per account)
- **No N+1 queries** (uses includes/preloading)
- **Fast response** (calculated on-demand, not background job)

### 4. Scalability
- **Works with multiple accounts** (personal, aggressive, family)
- **Supports future features** (account-specific dashboards)
- **Extensible** for portfolio analytics

---

## Next Steps

1. **Review this refactor plan** - Confirm approach is correct
2. **Implement changes** - Follow checklist above
3. **Write tests** - Cover all scenarios
4. **Manual testing** - Verify in browser
5. **Deploy to staging** - Test with real-like data
6. **Deploy to production** - Monitor closely

**Ready to execute?** This refactor touches 4 files (2 models, 1 controller, 1 view) and improves accuracy significantly.
