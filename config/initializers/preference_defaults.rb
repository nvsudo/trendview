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
    "visible" => ["total_account_size", "cash", "pnl_today", "net_pnl"],
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
