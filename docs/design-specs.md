# Design Specifications - TradeFlow

## Current Design System (Installed)

### Foundation: Maybe Finance Design System
**Location:** `app/assets/tailwind/maybe-design-system.css`

**Typography:**
- Font Family: Geist (primary), Geist Mono (monospace)
- Semantic Classes: Uses semantic design tokens (not raw Tailwind)

**Color System (Semantic Tokens):**
```
Text Colors:
- text-primary    → #0B0B0B (near black, main content)
- text-secondary  → #5C5C5C (gray, supporting text)
- text-tertiary   → #737373 (light gray, subtle text)

Background Colors:
- bg-surface      → #F7F7F7 (page background)
- bg-container    → #FFFFFF (card/container backgrounds)

State Colors:
- text-success    → #12B76A (green-600, positive values)
- text-destructive → #EC2222 (red-600, negative values)
- text-warning    → #F79009 (yellow-600)

Borders:
- border-primary  → #CFCFCF (gray-300)
- border-secondary → #E7E7E7 (gray-200)
- border-border   → #E7E7E7 (default border)
```

**Spacing & Layout:**
- Border Radius: 16px (`rounded-2xl`) for cards
- Shadows: `shadow-xs`, `shadow-sm`, `shadow-md` (subtle, 6% black alpha)
- Container Width: `max-w-7xl` (1280px)
- Grid System: Tailwind responsive grid (1/2/4 columns)

**Component Patterns:**
- Cards: White background, 1px border, 16px radius, subtle shadow
- Forms: `form-field` class with focus states and semantic tokens
- Tables: Semantic borders, hover states
- Buttons: Semantic backgrounds with hover transitions

---

## Figma Design System (Target)

### Typography
**Font Family:** Arimo (Google Font - needs to be added)
- Regular (400 weight) used for all text
- No bold/semibold in the design samples

**Font Sizes:**
```
Label Text:    14px (line-height: 20px / 143%)
Value Text:    32px (line-height: 32px / 100%)
Change Text:   14px (line-height: 20px / 143%)
```

### Color Palette
```css
/* Primary Text */
--figma-text-primary: #0A0A0A (near black, slightly different from Maybe's #0B0B0B)

/* Secondary Text */
--figma-text-secondary: #717182 (blue-gray, different from Maybe's #5C5C5C)

/* Success/Positive */
--figma-success: #00A63E (green, different from Maybe's #12B76A)

/* Backgrounds */
--figma-bg-white: #FFFFFF (same as Maybe)
--figma-bg-surface: TBD (need to see from full dashboard)

/* Borders */
--figma-border: rgba(0, 0, 0, 0.1) (10% black, very subtle - thinner than Maybe's solid borders)
```

### Component Specs

#### Dashboard Stat Card
```css
Dimensions:
- Width: 311px (fixed desktop size)
- Height: 106px
- Padding: 19px (top/left), varies by element position
- Border: 1.11px solid rgba(0,0,0,0.1)
- Border Radius: 16px
- Background: #FFFFFF
- Shadow: None visible (vs Maybe's subtle shadow)

Layout (absolute positioning in Figma):
- Label: top: 4px, left: 19px
- Value: top: 33px, left: 19px
- Change: top: 73px, left: 19px

Typography:
- Label: Arimo 14px/20px, #717182
- Value: Arimo 32px/32px, #0A0A0A
- Change: Arimo 14px/20px, #00A63E
```

---

## Dashboard Page: Current Implementation vs. Figma

### ✅ Already Built (Yesterday)

**Holdings/Positions System:**
- Database: `holding_sections` table with user-scoped sections
  - Fields: `name`, `description`, `position`, `color`, `is_default`
  - Default sections: "Core Holdings" (#3B82F6), "Probe Holdings" (#10B981)
- Database: `positions` table linked to sections
  - Fields: `holding_section_id`, `quantity`, `average_price`, `unrealized_pnl`, etc.
  - Supports: long/short positions, generation tracking, auto-close
- Model: `HoldingSection` with `has_many :positions`
- Model: `Position` with `belongs_to :holding_section, optional: true`
- Controller: `HoldingSectionsController` for CRUD
- Controller: `PositionsController` with move_to_section action
- Views: Dashboard renders sections with drag-drop (Stimulus)
- UI: Collapsible sections, color indicators, position tables
- Columns shown: Symbol, Qty, LTP, P&L, %

**Dashboard Stats Cards:**
- ✅ Total Value card
- ✅ Cash card (shows percentage)
- ✅ P&L Today card
- ✅ Net P&L card
- Data: `@portfolio_stats` hash from controller

**Market Feed:**
- ✅ Market indices (NIFTY, SENSEX, BANKNIFTY)
- ✅ Basic news feed with timestamps
- ✅ Live/News toggle buttons

**Performance Section:**
- ✅ Time period selector (1D, 1W, 1M, 1Y, ALL)
- ✅ Chart placeholder
- ✅ Performance metrics (placeholders)

---

## 🎨 DESIGN Changes (Visual Only - Separate Document)

**Note:** Design changes (fonts, colors, borders, spacing) are cosmetic updates that don't change functionality. These are tracked separately and can be implemented independently of features.

**Typography:**
- 🎨 Font: Geist → Arimo
- 🎨 Font weight: 600 (semibold) → 400 (regular)

**Colors:**
- 🎨 Secondary text: #5C5C5C → #717182 (blue-gray)
- 🎨 Success green: #12B76A → #00A63E
- 🎨 Border: solid rgba(231,231,231,1) → rgba(0,0,0,0.1)

**Component Styling:**
- 🎨 Card border: 1px solid → 1.11px rgba
- 🎨 Card shadow: subtle shadow-xs → none (flat)
- 🎨 Card width: responsive grid → fixed 311px

---

## ⚙️ FEATURE Requirements (New Functionality)

### 1. **[FEATURE] Table Column Customization**
**What:** Users can configure which columns to show in positions tables
**Why:** Different traders want different data (some care about weight %, others about absolute values)

**Requirements:**
- Gear icon ⚙️ on positions table header (top right)
- Modal/dropdown to toggle columns on/off
- Available columns to configure:
  - ✅ Symbol (always visible, cannot hide)
  - ⚙️ Weight % (portfolio weight)
  - ✅ Quantity (currently shown)
  - ✅ LTP - Last Traded Price (currently shown)
  - ⚙️ Invested (cost basis)
  - ⚙️ Current (current value)
  - ✅ P&L (absolute, currently shown)
  - ✅ P&L % (percentage, currently shown)
  - ⚙️ Tags (buy/sell indicators - see Feature #3)

**Database Needed:**
```sql
-- New table required
create_table "user_ui_preferences", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.string "preference_key", null: false  -- e.g., "dashboard_positions_columns"
  t.jsonb "preference_value", default: {}  -- e.g., {"symbol": true, "weight": true, "qty": false}
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["user_id", "preference_key"], unique: true
end
```

**Default Columns Shown:**
- Symbol ✅
- Qty ✅
- LTP ✅
- P&L ✅
- P&L % ✅

**Implementation Tasks:**
- [ ] Create `user_ui_preferences` table migration
- [ ] Create `UserUiPreference` model
- [ ] Add association to User model: `has_many :ui_preferences`
- [ ] Create preferences controller/endpoints (save/load)
- [ ] Add gear icon to positions table header
- [ ] Build column toggle UI (modal or dropdown)
- [ ] Save preferences to database via AJAX
- [ ] Update table rendering to respect user preferences
- [ ] Add preference seed for new users (default columns)

---

### 2. **[FEATURE] Position Weight Calculation**
**What:** Show portfolio weight % for each position
**Why:** Traders need to see concentration risk (Figma shows 15.2%, 12.8%, etc.)

**Requirements:**
- Calculate weight: `(position_value / total_portfolio_value) * 100`
- Add Weight column to positions table (configurable, see Feature #1)
- Display format: "15.2%" (1 decimal place)
- Sort positions by weight (optional)

**Data Source:**
- Position value: `position.current_value` (already exists)
- Total portfolio value: `@portfolio_stats[:total_value]` (already calculated)

**Implementation Tasks:**
- [ ] Add `portfolio_weight_percent` method to Position model
  ```ruby
  def portfolio_weight_percent(total_portfolio_value)
    return 0 if total_portfolio_value.zero?
    (current_value / total_portfolio_value * 100).round(1)
  end
  ```
- [ ] Update holdings section partial to include Weight column
- [ ] Pass `@portfolio_stats[:total_value]` to holdings partial
- [ ] Make Weight column configurable via user preferences (Feature #1)
- [ ] Add Weight to Figma columns list in settings UI

---

### 3. **[FEATURE] Buy/Sell Sentiment Tags**
**What:** Visual tags showing "buy" or "sell" recommendations on positions
**Why:** Quick visual cues for action items (Figma shows "sell" on GOOGL, "buy" on TSLA)

**Requirements:**
- Display tags: 🟢 "buy" (green) or 🔴 "sell" (red) or ⚪ "hold" (gray)
- Visual design: small pill/badge next to symbol
- Make tag column configurable (see Feature #1)

**Questions to Answer (DECISION NEEDED):**
- Where does buy/sell signal come from?
  - **Option A:** Manual user tagging (user sets tag per position)
  - **Option B:** AI/algorithm based on position performance
  - **Option C:** External signal provider API
  - **Option D:** Rule-based (e.g., "sell if down >10%", "buy if up >20%")

**Database Changes:**
```sql
-- Add to positions table
ALTER TABLE positions ADD COLUMN sentiment_tag VARCHAR DEFAULT 'none';
-- Values: 'buy', 'sell', 'hold', 'none'
```

**Implementation Tasks (Pending Decision):**
- [ ] **DECIDE:** Tag logic/source (A/B/C/D above)
- [ ] Add `sentiment_tag` column to positions table
- [ ] Add enum to Position model: `enum sentiment_tag: { none: "none", buy: "buy", sell: "sell", hold: "hold" }`
- [ ] Build tag display component (pill with icon + text)
- [ ] IF Manual (Option A): Add UI to set/update tags per position
- [ ] IF Automated (Option B/D): Build rules engine or AI integration
- [ ] IF External (Option C): Integrate signal provider API
- [ ] Add Tags column to preferences UI (Feature #1)

---

### 4. **[FEATURE] Enhanced Market Feed with Social Engagement**
**What:** Rich news feed with sources, authors, tickers, upvotes, comments
**Why:** Community-driven insights and engagement (Figma shows full social features)

**Requirements:**
- News source badges: "AI Insights" (purple), "Bloomberg" (blue), "Goldman Sachs" (blue), etc.
- Author attribution: "FlowBot", "Nick Timiraos", "David Vogt", etc.
- Clickable stock ticker tags: $NVDA, $SPY, $QQQ, etc.
- Engagement metrics: upvote/downvote count, comment count
- Sentiment indicators: "bullish" / "bearish" tags
- Timestamp display: "9m ago", "15m ago", "1h ago"

**Sample News Items (from Figma):**
1. **AI Insights** • FlowBot • 9m ago • "Unusual options flow detected" • 3x normal call volume in NVDA • $NVDA • ⬆24 💬8 • bullish
2. **Bloomberg** • Nick Timiraos • 15m ago • "Fed signals potential rate cuts in Q2 2024" • $SPY $QQQ $TLT • ⬆156 💬42 • bullish
3. **Goldman Sachs** • David Vogt • 1h ago • "AAPL price target raised to $210" • $AAPL • ⬆89 💬23 • bullish

**Database Schema:**
```sql
create_table "market_news_items", force: :cascade do |t|
  t.string "headline", null: false
  t.text "description"
  t.string "source"  -- "AI Insights", "Bloomberg", "Goldman Sachs", etc.
  t.string "author"  -- "FlowBot", "Nick Timiraos", "David Vogt", etc.
  t.string "source_url"
  t.string[] "ticker_tags"  -- ["NVDA", "SPY", "QQQ"]
  t.string "sentiment"  -- "bullish", "bearish", "neutral"
  t.integer "upvotes", default: 0
  t.integer "downvotes", default: 0
  t.integer "comments_count", default: 0
  t.datetime "published_at"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["published_at"], order: :desc
  t.index ["source"]
end

create_table "news_votes", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.bigint "market_news_item_id", null: false
  t.integer "vote_type"  -- 1 for upvote, -1 for downvote
  t.datetime "created_at", null: false
  t.index ["user_id", "market_news_item_id"], name: "index_news_votes_unique", unique: true
end

create_table "news_comments", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.bigint "market_news_item_id", null: false
  t.text "content", null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["market_news_item_id"]
  t.index ["user_id"]
end
```

**Implementation Tasks:**
- [ ] Create migrations: `market_news_items`, `news_votes`, `news_comments`
- [ ] Create models: `MarketNewsItem`, `NewsVote`, `NewsComment`
- [ ] Add associations:
  - `MarketNewsItem has_many :votes, :comments`
  - `User has_many :news_votes, :news_comments`
- [ ] Build MarketNewsController with actions:
  - `index` - list news items
  - `upvote` - toggle upvote
  - `downvote` - toggle downvote
- [ ] Build CommentsController for news comments
- [ ] Create news card component with all metadata:
  - Source badge (colored pill)
  - Author + timestamp
  - Headline + description
  - Ticker tags (clickable, filters by ticker)
  - Engagement UI (upvote/downvote buttons, comment count)
  - Sentiment tag ("bullish"/"bearish")
- [ ] Implement upvote/downvote functionality (AJAX)
- [ ] Implement comment threading UI
- [ ] Add ticker tag click → filter news by ticker
- [ ] **DECIDE:** News source (API integration or seed mock data?)
- [ ] IF API: Integrate news provider (Alpha Vantage, NewsAPI, etc.)
- [ ] IF Mock: Seed realistic news data for demo

---

### 5. **[FEATURE] "Open Positions" Action Link**
**What:** Clickable link in positions section header
**Why:** Quick navigation to full positions management view

**Requirements:**
- Link text: "→ Open Positions" or "Open Positions →"
- Placement: Right side of "Positions" heading
- Click behavior: Navigate to positions index page OR expand all sections
- Visual: Subtle text link, hover effect

**Implementation Tasks:**
- [ ] Add link to holdings section header partial
- [ ] **DECIDE:** Destination behavior:
  - Option A: Navigate to `/positions` (full CRUD view)
  - Option B: Expand all collapsed sections in dashboard
  - Option C: Toggle between "All" and "Open Only" filter
- [ ] Style link to match Figma design (subtle, right-aligned)
- [ ] Add hover state (color change or underline)

---

### 6. **[FEATURE] Watchlist Section Enhancement**
**What:** Dedicated section for securities user is watching (not holding)
**Why:** Track potential trades without committing capital

**Current Status:**
- Watchlist is a `HoldingSection` with name "Watchlist"
- Can theoretically contain positions with `quantity > 0`
- Not clearly differentiated from holdings in UI/data model

**Requirements:**
- Display watchlist securities (stocks user wants to track)
- Show: Symbol, LTP, Day Change %, "Add to Position" button
- Different layout than positions (no Qty/Invested/P&L columns)
- Quick add from market feed or search

**Data Model Decision Needed:**
- **Option A:** Use `positions` with `quantity: 0` in Watchlist section
  - Pro: Reuses existing infrastructure
  - Con: Confusing (position with no quantity?)
- **Option B:** Create separate `watchlist_items` table
  - Pro: Clear separation of concerns
  - Con: More code, another table
- **Option C:** Use `holding_section` with special flag `is_watchlist: true`
  - Pro: Leverages sections system
  - Con: Watchlist items aren't really "positions"

**Recommended: Option B (Separate Table)**
```sql
create_table "watchlist_items", force: :cascade do |t|
  t.bigint "user_id", null: false
  t.bigint "security_id", null: false
  t.text "notes"  -- User notes on why watching
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["user_id", "security_id"], unique: true
  t.index ["user_id"]
  t.index ["security_id"]
end
```

**Implementation Tasks:**
- [ ] **DECIDE:** Data model (Option A/B/C above)
- [ ] IF Option B: Create `watchlist_items` table + model
- [ ] Create WatchlistController (add, remove items)
- [ ] Build watchlist display component (different from positions table)
- [ ] Add "Add to Watchlist" button (market feed, search results, etc.)
- [ ] Add "Move to Position" button on watchlist items
- [ ] Show LTP + day change for watchlist items
- [ ] Add notes/memo field per watchlist item

---

## Summary: FEATURE Work Remaining

### ✅ Complete
1. Holdings/Positions System (built yesterday)

### 🔴 High Priority (MVP)
2. **Table Column Customization** - Gear icon + user preferences (NEW TABLE NEEDED)
3. **Position Weight Calculation** - Portfolio % per position (NEW MODEL METHOD)

### 🟡 Medium Priority (Post-MVP)
4. **Buy/Sell Sentiment Tags** - Visual action indicators (DECISION NEEDED + NEW COLUMN)
5. **Open Positions Link** - Quick navigation (SIMPLE)

### 🟢 Low Priority (Future / Nice-to-Have)
6. **Enhanced Market Feed** - Full social engagement (3 NEW TABLES)
7. **Watchlist Enhancement** - Separate from positions (DECISION NEEDED + POSSIBLE NEW TABLE)

---

## Infrastructure Summary

### Database Migrations Needed:

**High Priority:**
- [ ] `user_ui_preferences` table (for Feature #1: column customization)

**Medium Priority:**
- [ ] `sentiment_tag` column on `positions` (for Feature #3: buy/sell tags)

**Low Priority:**
- [ ] `market_news_items` table (for Feature #4: social news feed)
- [ ] `news_votes` table (for Feature #4: engagement)
- [ ] `news_comments` table (for Feature #4: discussions)
- [ ] `watchlist_items` table OR enhance positions logic (for Feature #6)

### Model Methods Needed:

**High Priority:**
- [ ] `Position#portfolio_weight_percent(total_value)` (for Feature #2)

**Medium Priority:**
- [ ] `UserUiPreference.get(user, key)` and `.set(user, key, value)` (for Feature #1)

**Low Priority:**
- [ ] `MarketNewsItem#upvote_by(user)`, `#downvote_by(user)` (for Feature #4)
- [ ] `User#watchlist_items` association (for Feature #6)

---

## Next Steps (Awaiting Your Decision)

1. **Review Feature List Above** - Which features are MVP vs. post-MVP?
2. **Answer Key Questions:**
   - Feature #3: How to determine buy/sell tags? (Manual/AI/Rules/API?)
   - Feature #4: News source? (API integration or mock data for now?)
   - Feature #6: Watchlist data model? (Separate table or positions with qty=0?)
3. **Prioritize Execution Order** - Start with high priority features?
4. **Design Changes** - Defer design updates or do in parallel with features?

**Recommendation:** Start with Features #1 (column customization) and #2 (weight calculation) since they're core trading functionality and don't require external decisions. Then tackle #3-#6 once we've decided on data sources and logic.
