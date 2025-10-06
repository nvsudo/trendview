# Positions Page - Complete Specification
## Chart-Hero Layout with Trade Planning System

**Last Updated**: 2025-10-04
**Status**: Final Specification - Ready for Implementation
**Philosophy**: Left → Right → Below. Chart is the hero. Go deeper as you go right or below.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Competitive Research Summary](#competitive-research-summary)
3. [Charting Technology Stack](#charting-technology-stack)
4. [Market Data Architecture](#market-data-architecture)
5. [Page Layout Structure](#page-layout-structure)
6. [Component Specifications](#component-specifications)
7. [Trade Planning System](#trade-planning-system)
8. [Data Models](#data-models)
9. [Implementation Details](#implementation-details)
10. [Implementation Checklist](#implementation-checklist)

---

## Design Philosophy

### Information Architecture: Progressive Disclosure

```
LEFT (300px)     →  Quick navigation, portfolio overview
CENTER (600px)   →  CHART HERO - Price action visualization
RIGHT (280px)    →  Historical context (trades & notes)
BELOW (full)     →  ACTION - Trade planning and execution
```

### Key Design Principles

1. **Chart as Hero**: 600px height chart dominates the page
2. **Space Efficiency**: Horizontal metrics row (80px) vs vertical table (400px) - saves 520px
3. **Planning-First**: Plan → Chart Marker → Execute → Learn workflow
4. **Incremental Mindset**: Show each position entry separately with individual P&L
5. **Left-to-Right Action Flow**: Shallow overview → Deep analysis → Action planning

---

## Charting Technology Stack

### Decision: Lightweight Charts by TradingView

**Library**: [Lightweight Charts](https://tradingview.github.io/lightweight-charts/) (Open Source, Apache 2.0)
**Status**: ✅ **Selected for MVP** (Option 2)
**Version**: 4.1.x (latest stable)

#### Why Lightweight Charts?

**Technical traders need candlesticks and volume** - not just line charts. Lightweight Charts is purpose-built for financial markets:

1. **Candlestick Charts (OHLC)**: Show Open, High, Low, Close - essential for reading price action patterns (pinbars, engulfing candles, dojis)
2. **Volume Bars**: Display institutional activity below price chart - critical for technical analysis
3. **Trade Markers**: Built-in marker system for buy/sell arrows and planned entry indicators
4. **Market-Agnostic**: Works with ANY market data (NSE, BSE, NYSE, NASDAQ, crypto)
5. **Performance**: Handles 10,000+ candles smoothly with zoom/pan
6. **Professional**: Used by Binance, Crypto.com, major crypto exchanges
7. **Free**: No licensing costs, open-source

#### Core Features Used

```javascript
// Candlestick series (main chart)
const candlestickSeries = chart.addCandlestickSeries({
  upColor: '#00A63E',      // Green candles (price up)
  downColor: '#E7000B'     // Red candles (price down)
})

// Volume series (bottom pane)
const volumeSeries = chart.addHistogramSeries({
  priceScaleId: 'volume',  // Separate scale
  scaleMargins: { top: 0.8, bottom: 0 }  // Bottom 20% of chart
})

// Trade markers (overlays)
candlestickSeries.setMarkers([
  { time: '2024-07-05', position: 'belowBar', shape: 'arrowUp', color: '#00A63E', text: 'Buy 90 @ ₹730' },
  { time: '2024-12-15', position: 'aboveBar', shape: 'arrowDown', color: '#E7000B', text: 'Sell 40 @ ₹1,095' },
  { time: '2024-12-20', position: 'belowBar', shape: 'circle', color: '#3B82F6', text: 'Plan: Add 50 @ ₹1,200' }
])
```

#### Installation (Rails 8 Importmap)

```ruby
# config/importmap.rb
pin "lightweight-charts", to: "https://cdn.jsdelivr.net/npm/lightweight-charts@4.1.3/dist/lightweight-charts.standalone.production.js"
```

Or via command:
```bash
bin/importmap pin lightweight-charts
```

#### Integration with Rails

- **Stimulus Controller**: `trading_chart_controller.js` handles chart rendering
- **Turbo Frame**: Chart section wrapped in `<turbo-frame id="position-chart">` for time period changes
- **Data Format**: Controller passes OHLC JSON via `data-trading-chart-candlesticks-value`
- **Responsive**: Auto-resizes on window resize, mobile-friendly with touch gestures

---

### Post-MVP: TradingView Advanced Charts (Option 3)

**Status**: 🔮 **Future Consideration** (Phase 2+)
**Type**: Paid embedded widget
**Cost**: $495-$995/month

#### When to Upgrade

Consider TradingView Advanced Charts when users demand:

1. **100+ Technical Indicators**: RSI, MACD, Bollinger Bands, Ichimoku Cloud, etc.
2. **Drawing Tools**: Trendlines, Fibonacci retracements, support/resistance zones
3. **Multi-Timeframe Analysis**: Compare 1H, 4H, 1D charts side-by-side
4. **Alerts System**: Price alerts, indicator crossovers
5. **Advanced Order Types**: Stop-limit, trailing stops, OCO (One-Cancels-Other)

#### Integration Approach (When Needed)

```html
<!-- TradingView Advanced Charts Widget (iframe embed) -->
<div class="tradingview-widget-container">
  <div id="tradingview_chart"></div>
  <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      "symbol": "NSE:RELIANCE",
      "interval": "D",
      "container_id": "tradingview_chart",
      "datafeed": new Datafeeds.UDFCompatibleDatafeed("https://your-backend.com/api/tradingview"),
      "library_path": "/charting_library/",
      "allow_symbol_change": true,
      "studies": ["Volume@tv-basicstudies", "RSI@tv-basicstudies"]
    })
  </script>
</div>
```

**Decision Point**: Upgrade when >20% of users request advanced indicators or you see Power User segment emerge.

---

## Market Data Architecture

### Multi-Market Data Strategy

TradeFlow will support **multiple global markets** with different data providers per region:

| Market | Data Source | Coverage | Cost | Status |
|--------|-------------|----------|------|--------|
| **India (NSE/BSE)** | Zerodha Kite Connect | All NSE/BSE stocks | ₹2,000/month | ✅ MVP |
| **US (NYSE/NASDAQ)** | Alpha Vantage API | US stocks | Free (500 calls/day) → $49/mo (unlimited) | 🔮 Phase 2 |
| **Crypto** | Binance API | BTC, ETH, altcoins | Free | 🔮 Phase 2 |
| **Forex** | Twelve Data API | Major currency pairs | $79/month | 🔮 Phase 3 |
| **UK/EU (LSE/XETRA)** | EOD Historical Data | European stocks | $79/month | 🔮 Phase 3 |

### Data Storage: Backend Database

**YES - All market data is stored in your PostgreSQL database.**

#### Why Store Data Locally?

1. **Performance**: Instant chart loading (no API calls on every page load)
2. **Cost Control**: Avoid excessive API calls (Zerodha charges per call beyond limits)
3. **Reliability**: Works even if data provider has downtime
4. **Historical Analysis**: Run custom queries (e.g., "Find all stocks with volume >2× average")
5. **Compliance**: Keep audit trail of prices used for P&L calculations
6. **Offline Mode**: Users can review charts even without internet

#### Data Model: `price_updates` Table

```ruby
# db/schema.rb
create_table "price_updates" do |t|
  t.references :security, null: false, foreign_key: true
  t.date :date, null: false                           # Trading date

  # OHLC (Candlestick data)
  t.decimal :open_price, precision: 10, scale: 2      # Opening price
  t.decimal :high_price, precision: 10, scale: 2      # High of the day
  t.decimal :low_price, precision: 10, scale: 2       # Low of the day
  t.decimal :close_price, precision: 10, scale: 2     # Closing price

  # Volume
  t.bigint :volume                                     # Shares traded

  # Metadata
  t.string :data_source                                # 'zerodha', 'alpha_vantage', 'binance'
  t.timestamps

  # Indexes for fast queries
  t.index [:security_id, :date], unique: true          # One record per day
  t.index :date                                        # Filter by date range
  t.index :data_source                                 # Filter by provider
end
```

#### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER OPENS POSITION PAGE                                 │
│    GET /positions?selected_id=123&period=1Y                  │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. RAILS CONTROLLER                                          │
│    PositionsController#index                                 │
│                                                              │
│    @chart_data = fetch_chart_data(position, '1Y')           │
│    ├─ Query: price_updates WHERE security_id = 456          │
│    │         AND date >= '2023-12-05'                        │
│    │         ORDER BY date ASC                               │
│    └─ Returns: 252 rows (1 year of daily candles)           │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. DATABASE (PostgreSQL)                                     │
│    price_updates table                                       │
│                                                              │
│    security_id | date       | open | high | low  | close    │
│    456        | 2024-07-05 | 725  | 735  | 720  | 730      │
│    456        | 2024-07-08 | 730  | 750  | 728  | 748      │
│    456        | 2024-07-09 | 748  | 760  | 745  | 755      │
│    ...        | ...        | ...  | ...  | ...  | ...      │
│    456        | 2024-12-20 | 1160 | 1180 | 1155 | 1168     │
│                                                              │
│    → Returns in 20ms (indexed query)                         │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. VIEW RENDERS                                              │
│    <div data-trading-chart-candlesticks-value=               │
│         '[{"time":"2024-07-05","open":725,"high":735,...}]'> │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. JAVASCRIPT (Lightweight Charts)                           │
│    trading_chart_controller.js                               │
│                                                              │
│    Renders 252 candles + volume bars + trade markers        │
│    User sees interactive chart in browser                   │
└─────────────────────────────────────────────────────────────┘
```

#### Background Data Sync (Automated)

**Daily Job**: Sync market data every trading day after market close

```ruby
# app/jobs/sync_market_data_job.rb
class SyncMarketDataJob < ApplicationJob
  queue_as :default

  def perform
    Security.active.find_each do |security|
      sync_security_data(security)
    end
  end

  private

  def sync_security_data(security)
    # Determine data source based on security's exchange
    service = case security.exchange
              when 'NSE', 'BSE'
                DataSources::ZerodhaService.new
              when 'NYSE', 'NASDAQ'
                DataSources::AlphaVantageService.new
              when 'BINANCE'
                DataSources::BinanceService.new
              else
                return # Unsupported exchange
              end

    # Fetch last 30 days (backfill any gaps)
    from_date = 30.days.ago.to_date
    to_date = Date.today

    ohlc_data = service.fetch_historical_data(
      symbol: security.symbol,
      from: from_date,
      to: to_date,
      interval: 'day'
    )

    # Upsert into database (insert or update if exists)
    ohlc_data.each do |data|
      PriceUpdate.upsert(
        {
          security_id: security.id,
          date: data[:date],
          open_price: data[:open],
          high_price: data[:high],
          low_price: data[:low],
          close_price: data[:close],
          volume: data[:volume],
          data_source: service.name,
          updated_at: Time.current
        },
        unique_by: [:security_id, :date]  # Conflict resolution
      )
    end

    Rails.logger.info "Synced #{ohlc_data.size} candles for #{security.symbol}"
  end
end
```

**Scheduled Execution**:
```ruby
# config/schedule.rb (using Whenever gem)
every 1.day, at: '6:00 pm' do  # After Indian market close (3:30 PM + buffer)
  runner "SyncMarketDataJob.perform_later"
end

# Or using Sidekiq Cron:
Sidekiq::Cron::Job.create(
  name: 'Daily Market Data Sync',
  cron: '0 18 * * 1-5',  # 6 PM, Mon-Fri (trading days)
  class: 'SyncMarketDataJob'
)
```

### Data Source Abstraction Layer

**Service Pattern**: Each data provider has its own adapter class

```ruby
# app/services/data_sources/base_service.rb
module DataSources
  class BaseService
    def fetch_historical_data(symbol:, from:, to:, interval: 'day')
      raise NotImplementedError, "Subclass must implement fetch_historical_data"
    end

    def fetch_live_quote(symbol)
      raise NotImplementedError, "Subclass must implement fetch_live_quote"
    end

    def name
      self.class.name.demodulize.gsub('Service', '').downcase
    end
  end
end

# app/services/data_sources/zerodha_service.rb
module DataSources
  class ZerodhaService < BaseService
    def initialize
      @kite = KiteConnect::KiteConnect.new(api_key: ENV['ZERODHA_API_KEY'])
      @kite.set_access_token(ENV['ZERODHA_ACCESS_TOKEN'])
    end

    def fetch_historical_data(symbol:, from:, to:, interval: 'day')
      instrument_token = find_instrument_token(symbol)

      data = @kite.historical_data(
        instrument_token,
        from.strftime('%Y-%m-%d'),
        to.strftime('%Y-%m-%d'),
        interval
      )

      # Transform Zerodha format to standard format
      data.map do |candle|
        {
          date: candle['date'].to_date,
          open: candle['open'].to_f,
          high: candle['high'].to_f,
          low: candle['low'].to_f,
          close: candle['close'].to_f,
          volume: candle['volume'].to_i
        }
      end
    rescue KiteConnect::ApiError => e
      Rails.logger.error "Zerodha API error: #{e.message}"
      []
    end

    def fetch_live_quote(symbol)
      instrument_token = find_instrument_token(symbol)
      quote = @kite.quote([instrument_token])[instrument_token.to_s]

      {
        last_price: quote['last_price'].to_f,
        change: quote['change'].to_f,
        change_percent: quote['change_percent'].to_f,
        volume: quote['volume'].to_i,
        timestamp: Time.current
      }
    end

    private

    def find_instrument_token(symbol)
      # Cache instrument tokens in Redis
      Rails.cache.fetch("zerodha_instrument_#{symbol}", expires_in: 1.day) do
        instruments = @kite.instruments('NSE')
        instrument = instruments.find { |i| i['tradingsymbol'] == symbol }
        instrument&.fetch('instrument_token')
      end
    end
  end
end

# app/services/data_sources/alpha_vantage_service.rb
module DataSources
  class AlphaVantageService < BaseService
    BASE_URL = 'https://www.alphavantage.co/query'

    def fetch_historical_data(symbol:, from:, to:, interval: 'day')
      # Alpha Vantage uses different symbols (e.g., AAPL not AAPL.US)
      response = HTTP.get(BASE_URL, params: {
        function: 'TIME_SERIES_DAILY',
        symbol: symbol,
        apikey: ENV['ALPHA_VANTAGE_API_KEY'],
        outputsize: 'full'
      })

      data = JSON.parse(response.body)
      time_series = data['Time Series (Daily)'] || {}

      # Filter by date range and transform
      time_series
        .select { |date, _| Date.parse(date).between?(from, to) }
        .map do |date, values|
          {
            date: Date.parse(date),
            open: values['1. open'].to_f,
            high: values['2. high'].to_f,
            low: values['3. low'].to_f,
            close: values['4. close'].to_f,
            volume: values['5. volume'].to_i
          }
        end
        .sort_by { |d| d[:date] }
    rescue => e
      Rails.logger.error "Alpha Vantage API error: #{e.message}"
      []
    end
  end
end

# app/services/data_sources/binance_service.rb
module DataSources
  class BinanceService < BaseService
    BASE_URL = 'https://api.binance.com/api/v3'

    def fetch_historical_data(symbol:, from:, to:, interval: 'day')
      # Binance uses BTCUSDT format (crypto pairs)
      interval_map = { 'day' => '1d', 'hour' => '1h', 'minute' => '1m' }

      response = HTTP.get("#{BASE_URL}/klines", params: {
        symbol: symbol,
        interval: interval_map[interval],
        startTime: from.to_time.to_i * 1000,  # Binance uses milliseconds
        endTime: to.to_time.to_i * 1000,
        limit: 1000
      })

      data = JSON.parse(response.body)

      data.map do |candle|
        {
          date: Time.at(candle[0] / 1000).to_date,
          open: candle[1].to_f,
          high: candle[2].to_f,
          low: candle[3].to_f,
          close: candle[4].to_f,
          volume: candle[5].to_f
        }
      end
    rescue => e
      Rails.logger.error "Binance API error: #{e.message}"
      []
    end
  end
end
```

### Security Model Enhancement

```ruby
# app/models/security.rb
class Security < ApplicationRecord
  has_many :price_updates, dependent: :destroy
  has_many :positions

  # Enums
  enum exchange: {
    nse: 'NSE',
    bse: 'BSE',
    nyse: 'NYSE',
    nasdaq: 'NASDAQ',
    binance: 'BINANCE'
  }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_exchange, ->(exchange) { where(exchange: exchange) }

  # Methods
  def data_source_service
    case exchange
    when 'NSE', 'BSE'
      DataSources::ZerodhaService.new
    when 'NYSE', 'NASDAQ'
      DataSources::AlphaVantageService.new
    when 'BINANCE'
      DataSources::BinanceService.new
    else
      raise "Unsupported exchange: #{exchange}"
    end
  end

  def latest_price
    price_updates.order(date: :desc).first&.close_price
  end

  def ohlc_data(from:, to:)
    price_updates
      .where(date: from..to)
      .order(date: :asc)
      .pluck(:date, :open_price, :high_price, :low_price, :close_price, :volume)
      .map do |date, open, high, low, close, volume|
        {
          time: date.iso8601,
          open: open.to_f,
          high: high.to_f,
          low: low.to_f,
          close: close.to_f,
          volume: volume
        }
      end
  end
end
```

### Storage Costs & Optimization

**Database Size Estimation**:
- **1 security × 1 year**: 252 trading days × 80 bytes/row ≈ 20 KB
- **100 securities × 5 years**: 252 × 5 × 100 × 80 bytes ≈ 10 MB
- **1,000 securities × 10 years**: 252 × 10 × 1,000 × 80 bytes ≈ 200 MB

**Conclusion**: Data storage is **extremely cheap** (even 10,000 securities × 10 years = 2 GB).

**Optimization Strategies**:
1. **Partitioning**: Partition `price_updates` by year for faster queries
2. **Archiving**: Move data older than 5 years to cold storage (S3)
3. **Compression**: PostgreSQL can compress old partitions (reduces size by 50-70%)
4. **Selective Sync**: Only sync securities that users actually trade (user's watchlist)

### API Rate Limits & Costs

| Provider | Free Tier | Paid Tier | Rate Limit |
|----------|-----------|-----------|------------|
| **Zerodha Kite** | N/A | ₹2,000/month | 3 calls/sec (historical), Unlimited (live quotes) |
| **Alpha Vantage** | 500 calls/day | $49/month (unlimited) | 5 calls/min (free), No limit (paid) |
| **Binance** | Free | Free | 1,200 requests/min |
| **Twelve Data** | 800 calls/day | $79/month | 8 calls/min (free), 60/min (paid) |

**Cost Projection** (100 active users, 1,000 securities):
- **MVP (India only)**: ₹2,000/month (Zerodha Kite Connect)
- **Phase 2 (India + US)**: ₹2,000 + $49 = ~₹6,000/month
- **Phase 3 (Multi-market)**: ₹2,000 + $49 + $79 = ~₹12,000/month

**Optimization**: Cache aggressively, sync only user watchlists, batch API calls during off-peak hours.

---

## Competitive Research Summary

### What the Best Platforms Do

| Feature | Minervini 360 | Edgewonk | Seeking Alpha | **TradeFlow** |
|---------|---------------|----------|---------------|---------------|
| **Chart-Hero Layout** | ❌ Charts secondary | ❌ Charts separate | ❌ No charts | ✅ **Chart is primary (600px)** |
| **Trade Plan → Execution** | ✅ Integrated | ⚠️ Separate planning | ❌ No planning | ✅ **One-click save to plan** |
| **Incremental Scaling** | ✅ Manual tracking | ✅ Pre-defined rules | ❌ No scaling | ✅ **Visual scaling UI** |
| **Indian Market Focus** | ❌ US markets | ❌ Global (no NSE) | ❌ US markets | ✅ **NSE/BSE, ₹ formatted** |
| **Markdown Notes** | ❌ Rigid forms | ✅ Rich notes | ❌ Basic notes | ✅ **Markdown + templates** |
| **Plan Markers on Chart** | ❌ Not shown | ❌ Not shown | ❌ No charts | ✅ **📍 Planned, 🟢 Executed** |
| **Execution Variance** | ❌ Not tracked | ❌ Not tracked | ❌ N/A | ✅ **Planned vs Actual** |

**Our Unique Value**: Chart → Analysis → Plan → Execute in one continuous flow

### Key Insights from Research

**Minervini Markets 360** (Champion Trader):
- Progressive exposure: Start small, scale up only when winning
- 2:1 Reward:Risk minimum for entries
- 1% max risk per trade
- Integrated calculator → Planned trade → Executed increment

**Edgewonk** (Journal Excellence):
- Pre-trade plans as separate entities
- Scaling rules defined upfront
- Trade management rules for position adjustments
- Feedback loop on position sizing effectiveness

**Seeking Alpha Pro** (Portfolio Tracker):
- Auto-sync with brokerages
- Real-time performance tracking
- Customizable columns
- Rating integration + portfolio health score

**Industry Best Practices** (Pyramiding/Scaling):
- Initial position: 1-2% of capital
- Incremental adds: Each ≤ previous (1% → 0.75% → 0.5%)
- Stop adjustment: Raise to breakeven after first add
- Partial profit taking: 50% at first target, trail remainder

---

## Page Layout Structure

### Visual Flow (3 Columns + Bottom Panel)

```
┌────────────┬────────────────────────────┬─────────────┐
│            │                            │             │
│  LEFT      │      CENTER (HERO)         │    RIGHT    │
│  Position  │      📈 CHART              │    Trades   │
│  List      │      (600px height)        │    & Notes  │
│  (300px)   │                            │    (280px)  │
│            │                            │             │
│            ├────────────────────────────┤             │
│            │  Position Metrics Row      │             │
│            │  (Horizontal, 80px)        │             │
│            └────────────────────────────┘             │
│            ┌────────────────────────────┴─────────────┘
│            │  BELOW: TRADE PLANNING PANEL
│            │  • Active Plan
│            │  • New Plan Builder
│            │  • Past Plans (collapsed)
│            └──────────────────────────────
└────────────┴────────────────────────────┘
```

### Responsive Breakpoints

- **Desktop**: ≥1024px (3-column + bottom panel)
- **Tablet**: 768px-1023px (2-column, hide notes, bottom panel collapses)
- **Mobile**: <768px (single column, stack all sections)

---

## Component Specifications

### 1. TopBar (Full-Width, Sticky)

**Height**: 61px
**Background**: #FFFFFF
**Border**: 1.25px solid #E5E7EB (bottom only)
**Padding**: 12px 24px

#### Market Tickers (Left Section)

**Layout**: Horizontal flex row with 32px gaps

Each ticker shows:
- **Index Name** (14px, #4A5565 - gray)
- **Value** (14px, #0A0A0A - black, semibold)
- **Change** (12px, #00A63E green or #E7000B red)

**Example**:
```
NIFTY 50    19,674.25    +187.45 (0.96%)
S&P 500     4,567.18     +24.32 (0.53%)
NASDAQ      14,234.95    -12.45 (-0.09%)
DOW JONES   33,984.93    +156.22 (0.46%)
```

**Typography**:
- Index Name: Arimo 14px, #4A5565
- Value: Arimo 14px, #0A0A0A
- Change: Arimo 12px, #00A63E (positive) or #E7000B (negative)

#### Account Selector + Actions (Right Section)

**Components**:
1. **Account Dropdown**
   - Width: ~124px, Height: 36px
   - Background: #F3F4F6, Border-radius: 10px
   - Text: "All Accounts" (14px, #0A0A0A)

2. **Bell Icon** (Notifications): 32px × 32px, border-radius 10px

3. **Settings Icon**: 32px × 32px, border-radius 10px

**Gap**: 12px between elements

---

### 2. LEFT: Position List Sidebar (300px)

**Purpose**: Quick navigation, portfolio overview
**Background**: #FFFFFF
**Border-Right**: 1.25px solid #E5E7EB
**Padding**: 24px 24px 0

#### Sidebar Header

```
┌─────────────────────────────────────┐
│ Positions              [Open ▼]     │
└─────────────────────────────────────┘
```

**"Positions" Heading**: Arimo 18px, #0A0A0A, line-height 28px

**"Open" Filter Button**:
- Width: 60px, Height: 35px
- Background: #FFFFFF, Border: 1.25px solid #E5E7EB
- Border-radius: 10px, Text: 14px
- Toggle: "Open" ↔ "All" positions

#### Position Section Structure

**Each section includes**:
1. **Section Header** (collapsible with +/− icon)
2. **Column Headers** (Symbol, Weight, Invested, Current, P&L%)
3. **Position Rows** (clickable, selectable)

##### Section Header

```
┌─────────────────────────────────────┐
│ Core Holdings              [+]      │
└─────────────────────────────────────┘
```

**Styling**:
- Section Name: Arimo 14px, #717182, 12px left padding
- Collapse Icon: 24px button, + or − icon
- Gap below: 12px

##### Column Headers

```
┌─────────────────────────────────────┐
│ Symbol  Weight  Invested Current P&L%│
└─────────────────────────────────────┘
```

**Styling**:
- Font: Arimo 12px, #0A0A0A
- Border-bottom: 1.25px solid #F3F4F6
- Height: 33px, Padding: 0 12px

**Columns**:
1. Symbol (left-aligned, flex-grow: 1)
2. Weight (center, ~48px)
3. Invested (center, ~64px)
4. Current (center, ~64px)
5. P&L % (right, ~64px)

##### Position Row

**Normal State**:
```
┌─────────────────────────────────────┐
│ 🔲 AAPL  15.2%  15.2%  15.2%  +19.0%│
└─────────────────────────────────────┘
```

**Selected State** (blue highlight):
```
┌─────────────────────────────────────┐
│ 🔲 NVDA  7.3%   63K    78K   +25.0% │ ← Blue background
└─────────────────────────────────────┘
```

**Row Styling**:
- **Normal**: Height 36px, transparent background, border-radius 10px, hover: #F9FAFB
- **Selected**: Background #EFF6FF, border 1.25px solid #BEDBFF

**Row Content**:
1. Position Icon (12px × 12px gray grid icon)
2. Symbol (14px, #0A0A0A, 8px margin from icon)
3. Weight % (14px, centered)
4. Invested (14px, centered, "105K" format for large numbers)
5. Current (14px, centered, "118K" format)
6. P&L % (14px, #00A63E or #E7000B, right-aligned, with +/− sign)

**Sentiment Tags** (optional):
- **"buy" tag**: Background #DCFCE7, text #008236, 12px, border-radius 4px
- **"sell" tag**: Background #FFE2E2, text #C10007, 12px, border-radius 4px

**Number Formatting**:
- Values > 10,000: "105K", "118K" (compact)
- Values < 10,000: "15.2%" or "15.2" (decimal)
- P&L %: Always show sign (+/−), 1 decimal place

#### Quick Actions (Enhancement)

On hover, show contextual menu:
```
[•••] → • Add to Plan
        • Edit Position
        • Close Position
```

---

### 3. CENTER: Chart Hero (600px height, fluid width)

**Purpose**: Visualize price action + trade history + planned entries/exits
**Background**: White card with shadow
**Border-radius**: 12px
**Padding**: 24px

#### Chart Section

```
┌──────────────────────────────────────────────────────────┐
│ NVDA                   [1D 1W 1M 3M 6M 1Y ALL]           │
│ ₹1,168 (+2.3%)                                           │
│ 145 shares • Avg Cost ₹825 • Unrealized +₹49,692        │
│ ──────────────────────────────────────────────────────── │
│                                                           │
│     ₹1,200 ┤                           🎯       📍       │
│            │                      🟢                      │
│     ₹1,000 ├────────────────────────────────────         │
│            │               🟢                             │
│       ₹850 ├─────────────────────────                    │
│            │      🟢  🔴                                  │
│       ₹700 ├────────────────                             │
│            │                                              │
│       ₹600 └──────────────────────────────────           │
│            2023  2024-Q1  2024-Q2  2024-Q3  Now         │
│                                                           │
│ Legend:                                                   │
│ 🟢 Buy Orders (3 entries) | 🔴 Sell Orders (1 exit)      │
│ 📍 Planned Entry (₹1,200) | 🎯 Planned Target (₹1,400)   │
│ ─── Avg Cost (₹825)       | --- Stop Loss (₹950)         │
│ ──────────────────────────────────────────────────────── │
│ Hover markers for details • Click to edit plan           │
└──────────────────────────────────────────────────────────┘
```

**Chart Header**:
- **Symbol**: Arimo 18px, #0A0A0A
- **Current Price**: Arimo 32px, #0A0A0A (₹1,168)
- **Day Change**: Arimo 14px, #00A63E or #E7000B (+2.3%)
- **Position Summary**: Arimo 14px, #717182 (145 shares, avg, P&L)

**Time Filter Buttons**:
- Buttons: 1D, 1W, 1M, 3M, 6M, **1Y** (default selected), ALL
- Active: #0A0A0A background, white text, 28px height, border-radius 6px
- Inactive: transparent, #717182 text, hover: #F9FAFB

**Chart Features**:
1. **Price Line**: Green gradient fill below line
2. **Avg Cost Line**: Horizontal dashed gray line at ₹825
3. **Stop Loss Line**: Horizontal dashed red line at ₹950 (user-defined)
4. **Buy Order Markers**: 🟢 Green circles, size varies by position size
5. **Sell Order Markers**: 🔴 Red circles
6. **Planned Entry Markers**: 📍 Pin icon at planned price (from trade plans)
7. **Planned Target Markers**: 🎯 Target icon at planned exit price

**Interactive Features**:
- **Hover**: Show tooltip with trade details ("Dec 2: +35 shares @ ₹920, Entry #3")
- **Click Marker**: Highlight that trade in right sidebar
- **Click Plan Marker**: Open Trade Planning Panel with that plan

**Chart Controls** (below chart):
```
[Overlays ▼] Show: [✓] Avg Cost  [✓] Stop Loss  [✓] Planned Entries  [✓] Targets
```

**Chart Height**: 600px (vs original 120px - this is the hero!)

---

### 4. CENTER (Below Chart): Position Metrics Row

**Purpose**: Compact horizontal metrics strip
**Layout**: 2 rows × 6 columns grid
**Height**: ~80px total (vs 400px vertical table - saves 520px!)

```
┌────────────────────────────────────────────────────────────────────────┐
│ ┌─────────┬──────────┬──────────┬──────────┬──────────┬──────────────┐ │
│ │ WEIGHT  │ INVESTED │ CURRENT  │ UNREAL   │ DAY CHG  │ RISK LEVEL   │ │
│ │ 7.3%    │ ₹1,19,   │ ₹1,69,   │ +₹49,692 │ +₹53.89  │ [NORMAL]     │ │
│ │         │  668     │  360     │ (+41.5%) │ (+2.3%)  │ [green pill] │ │
│ └─────────┴──────────┴──────────┴──────────┴──────────┴──────────────┘ │
│ ┌─────────┬──────────┬──────────┬──────────┬──────────┬──────────────┐ │
│ │ QTY     │ AVG COST │ LTP      │ STOP     │ TARGET   │ R:R          │ │
│ │ 145     │ ₹825     │ ₹1,168   │ ₹950     │ ₹1,400   │ 2.1:1        │ │
│ │         │          │  [🟡Mkt] │ (-18.7%) │ (+19.9%) │              │ │
│ └─────────┴──────────┴──────────┴──────────┴──────────┴──────────────┘ │
│                                                          [Edit Values →]│
└────────────────────────────────────────────────────────────────────────┘
```

**Styling**:
- Background: White card (same as chart)
- Border-radius: 12px
- Padding: 16px 24px
- Shadow: Subtle (matches chart)
- Font: Arimo 14px for values, 12px for labels

**Column Details**:

**Row 1** (Portfolio View):
1. **Weight %**: Portfolio concentration (7.3% of total)
2. **Invested**: Total cost basis (₹1,19,668)
3. **Current**: Current market value (₹1,69,360)
4. **Unrealized P&L**: Gain/loss in ₹ and % (+₹49,692, +41.5%, green color)
5. **Day Change**: Today's movement (+₹53.89, +2.3%, green color)
6. **Risk Level**: Badge based on weight % (Normal: <10% green, High: >10% red)

**Row 2** (Trade View):
7. **Qty**: Number of shares owned (145)
8. **Avg Cost**: Average purchase price (₹825)
9. **LTP**: Last Traded Price (₹1,168) with yellow "Market" badge
10. **Stop**: Stop loss price (₹950, -18.7% from current, red color)
11. **Target**: Take profit target (₹1,400, +19.9% from current, green color)
12. **R:R**: Risk-to-reward ratio (2.1:1)

**Color Coding**:
- Green (#00A63E): Positive values, gains
- Red (#E7000B): Negative values, losses, stop loss
- Yellow badge (#FFF3CD bg, #F59E0B text): Live market data
- Green badge (#DCFCE7 bg, #008236 text): Normal risk
- Red badge (#FFE2E2 bg, #C10007 text): High risk

**Inline Edit**: Click "[Edit Values →]" → Modal opens for updating stop/target values

---

### 5. RIGHT: Trades & Notes Sidebar (280px)

**Purpose**: Quick trade history + notes (compact, simple)
**Background**: #FFFFFF
**Border-Left**: 1.25px solid #E5E7EB
**Padding**: 24px

---

#### Recent Trades (Compact Table)

```
┌──────────────────────────────────────┐
│ NVDA - Recent Trades  [View All →]   │
│ ──────────────────────────────────── │
│                                       │
│ DATE     B/S  Q    P                 │
│ ──────────────────────────────────   │
│ Dec 15   S    40   ₹1,095  [•]       │
│ Dec 2    B    35   ₹920    [•]       │
│ Nov 12   B    60   ₹748    [•]       │
│ Oct 15   S    30   ₹1,200  [•]       │
│ Aug 20   S    90   ₹850    [•]       │
│ Jul 5    B    90   ₹730    [•]       │
│ Jun 15   B    50   ₹680    [•]       │
│ May 10   S    50   ₹720    [•]       │
│ Apr 22   B    100  ₹650    [•]       │
│ Mar 8    S    100  ₹700    [•]       │
│                                       │
│ Showing 10 of 12 trades              │
│ [View All Trades →]                  │
└──────────────────────────────────────┘
```

**Design Philosophy**:
- **Simplicity First**: No cards, no tabs, just a clean table
- **Most Recent First**: Latest trades at top (reverse chronological)
- **Compact**: 4 columns only (Date, B/S, Qty, Price)
- **Max 10 Rows**: Show up to 10 most recent trades, then "View All" link
- **Click to Highlight**: Click row → Highlights that trade marker on chart
- **Quick Actions**: Dot menu [•] on hover for View/Edit/Delete

**Column Specifications**:

1. **DATE**: MMM DD format (Dec 15, Nov 12)
   - Font: Arimo 12px, #0A0A0A
   - Width: ~60px

2. **B/S**: Buy/Sell badge
   - **B** (Buy): Background #DCFCE7, text #008236, 20px × 18px, rounded 4px
   - **S** (Sell): Background #FFE2E2, text #C10007, 20px × 18px, rounded 4px
   - Font: Arimo 12px, bold
   - Width: ~32px

3. **Q** (Quantity): Right-aligned number
   - Font: Arimo 12px, #0A0A0A
   - Width: ~40px
   - Format: 40, 35, 60 (no commas for small numbers)

4. **P** (Price): Right-aligned price
   - Font: Arimo 12px, #0A0A0A
   - Width: ~70px
   - Format: ₹1,095, ₹920, ₹748 (Indian rupee symbol)

5. **[•]** (Actions Menu): Dot menu icon
   - Shows on row hover
   - Opens dropdown: View Details | View on Chart | Edit | Delete
   - Width: ~24px

**Table Styling**:
- Header row: Bold, #717182 color, border-bottom 1px solid #E5E7EB
- Data rows: Height 28px, hover background #F9FAFB
- Border-bottom: 1px solid #F3F4F6 (subtle separator between rows)
- Font: Arimo 12px throughout
- Scrollable if >10 trades (rare, since limit is 10)

**Interactive Behavior**:
- **Click Row**: Triggers `chart_controller` to highlight that trade marker
  ```javascript
  highlightTradeOnChart(tradeId) {
    // Find marker on chart, zoom to it, pulse animation
  }
  ```
- **Dot Menu Actions**:
  - **View Details**: Navigate to `/trades/:id` (full Trades page)
  - **View on Chart**: Scroll chart to this trade's date, highlight marker
  - **Edit**: Open trade edit modal
  - **Delete**: Confirm + delete trade

**Data Source**:
```ruby
@recent_trades = @selected_position.trades
                                   .order(created_at: :desc)
                                   .limit(10)
# Returns: [{ date: '2024-12-15', type: 'sell', qty: 40, price: 1095, id: 156 }, ...]
```

**Why This Works**:
- **Scannable**: User can quickly scan recent activity without tabs or cards
- **Action-Oriented**: Click row to see it on chart (most common action)
- **Minimal Friction**: No "View on Chart" buttons - just click the row
- **Defers Details**: Full trade analysis lives on `/trades` page, not cluttering sidebar

---

#### Notes Section (Below Trades)

```
┌──────────────────────────────────────┐
│ NVDA - Trading Notes   [+ New Note]  │
│ ──────────────────────────────────── │
│                                       │
│ WK#6 - Dec 4, 2024                   │
│ NVDA Entry Strategy                  │
│                                       │
│ Q3 guidance is incremental, should   │
│ continue through 2024. Target: ₹1200 │
│                                       │
│ Tags: [AI] [Growth]                  │
│ [Edit Note]  [Delete]                │
│                                       │
│ ───────────────────────────────────  │
│                                       │
│ WK#4 - Nov 15, 2024                  │
│ Stage 2 Breakout Confirmed           │
│                                       │
│ Pocket pivot on volume. RS line new  │
│ high. Added 2nd tranche @ ₹920.      │
│                                       │
│ Tags: [Stage2] [Add]                 │
│ [Edit Note]  [Delete]                │
│                                       │
│ [+ New Note]                         │
└──────────────────────────────────────┘
```

**Features**:
- **Markdown-Powered**: Same rich text editor as Journal page
- **Auto-Linked**: Notes automatically linked to NVDA security
- **Tags**: Filter by strategy, setup, action (Add, Trim, Hold)
- **Chronological**: Newest notes first
- **Week Labels**: "WK#6 - Dec 4, 2024" format

**Note Card Styling**:
- Background: #F9FAFB
- Border-radius: 8px
- Padding: 16px
- Margin-bottom: 12px

**Note Header**:
- Date: 12px, #717182
- Title: 14px, #0A0A0A, semibold

**Note Tags**:
- Background: #EFF6FF (light blue)
- Text: #3B82F6, 12px
- Border-radius: 12px, padding 4px 12px

**Data Source**: `journal_entries` where `security_id = xxx AND entry_type = 'watchlist_note'`

---

### 6. BELOW: Trade Planning Panel (Full-width, collapsible)

**Purpose**: The killer feature - plan your next move
**Layout**: Accordion-style expandable panel
**Background**: White card
**Border**: 1.25px solid #E5E7EB
**Border-radius**: 12px
**Margin-top**: 24px

#### Default State (Collapsed)

```
┌────────────────────────────────────────────────────────────────────────┐
│ 📋 TRADE PLANS                                              [Expand ▼] │
│ Active Plan: Add @ ₹1,200 (50 shares, -18.7% to stop) • Target: ₹1,400│
└────────────────────────────────────────────────────────────────────────┘
```

**One-liner shows**:
- Active plan icon (📋)
- Plan summary (action, price, qty, risk%, target)
- Expand button

**Height**: 48px collapsed

---

#### Expanded State

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ 📋 TRADE PLANS                                                      [Collapse ▲] │
│ ───────────────────────────────────────────────────────────────────────────────  │
│                                                                                   │
│ ┌─ ACTIVE PLAN ─────────────────────────────────────────┐                       │
│ │                                                        │                       │
│ │ Plan: Add to NVDA                       Status: OPEN   │                       │
│ │ Created: Dec 1, 2024                                   │                       │
│ │                                                        │                       │
│ │ ACTION        │ ENTRY PRICE  │ QTY    │ RISK      │ TARGET    │ R:R          │
│ │ Add (3rd)     │ ₹1,200       │ 50     │ ₹12,500   │ ₹1,400    │ 1.6:1        │
│ │               │              │        │ (1% acct) │ (+16.7%)  │              │
│ │                                                        │                       │
│ │ STOP LOSS: ₹950 (-20.8% from entry)                   │                       │
│ │ NOTES: Wait for pullback to 10-day MA. Volume must    │                       │
│ │ confirm (>40% above avg). Stage 2 still intact.       │                       │
│ │                                                        │                       │
│ │ [Edit Plan]  [Mark Executed]  [Cancel Plan]           │                       │
│ └────────────────────────────────────────────────────────┘                       │
│                                                                                   │
│ ┌─ NEW PLAN ────────────────────────────────────────────┐                       │
│ │                                                        │                       │
│ │ Action:  [● Add]  [ Hold]  [ Trim]  [ Close]          │                       │
│ │                                                        │                       │
│ │ Entry Price:      [₹________]  (Current: ₹1,168)      │                       │
│ │ Quantity:         [_____] shares                       │                       │
│ │ Stop Loss:        [₹________]  (% risk: _____%)        │                       │
│ │ Target:           [₹________]  (% gain: _____%)        │                       │
│ │                                                        │                       │
│ │ Risk Management:                                       │                       │
│ │ Risk Amount: ₹_____ (___% of account)                  │                       │
│ │ R:R Ratio:   ___:1  [✓] Meets 2:1 minimum             │                       │
│ │                                                        │                       │
│ │ Plan Notes:  [Markdown editor...]                      │                       │
│ │ ┌────────────────────────────────────────────┐        │                       │
│ │ │ Waiting for Stage 2 pullback to 10-day MA. │        │                       │
│ │ │ Entry criteria:                             │        │                       │
│ │ │ - [ ] Price at/near 10-day MA               │        │                       │
│ │ │ - [ ] Volume spike (>40% avg)               │        │                       │
│ │ │ - [ ] RS line holding                       │        │                       │
│ │ └────────────────────────────────────────────┘        │                       │
│ │                                                        │                       │
│ │ [Save as Trade Plan]  [Clear Form]                    │                       │
│ └────────────────────────────────────────────────────────┘                       │
│                                                                                   │
│ ┌─ PAST PLANS (3) ──────────────────────────────────────┐ [Expand ▼]           │
│ │ (Collapsed - click to view executed/cancelled plans)  │                       │
│ └────────────────────────────────────────────────────────┘                       │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

#### Active Plan Section

Shows current active plan for this position (only 1 active plan per position allowed).

**Key Fields**:
- **Action**: Add (increment), Hold (do nothing), Trim (reduce), Close (exit)
- **Entry Price**: Planned entry level (₹1,200)
- **Qty**: How many shares to add/remove (50)
- **Risk**: Amount risked in ₹ and % of account (₹12,500, 1%)
- **Target**: Take-profit level (₹1,400)
- **R:R**: Risk-to-reward ratio (1.6:1)
- **Stop Loss**: Where to exit if wrong (₹950)
- **Notes**: Markdown notes with entry criteria, conditions, reasoning

**Actions**:
- **Edit Plan**: Modal opens to modify any field
- **Mark Executed**: Converts plan → actual trade, links to trade record
- **Cancel Plan**: Idea didn't work out, archive plan with reason

**Styling**:
- Background: #F9FAFB (light gray card)
- Border: 1px solid #E5E7EB
- Border-radius: 8px
- Padding: 20px
- Margin-bottom: 16px

---

#### New Plan Builder

**Action Selector** (Radio buttons):
```
[● Add]  [ Hold]  [ Trim]  [ Close]
```

**Form Fields**:

1. **Entry Price Input**:
   - Placeholder: Current price pre-filled (₹1,168)
   - Validation: Must be within ±20% of current price
   - Real-time: Updates R:R as you type

2. **Quantity Input**:
   - Placeholder: Suggest qty based on 1% risk
   - Validation: Must be > 0

3. **Stop Loss Input**:
   - Placeholder: Empty (user must define)
   - Shows: % below entry price in real-time
   - Validation: Must be < entry price for long positions

4. **Target Input**:
   - Placeholder: Suggest 2× risk distance
   - Shows: % above entry price in real-time
   - Validation: Must be > entry price for long positions

**Risk Management Display** (auto-calculated):

```
Risk Management:
Risk Amount: ₹12,500 (1.0% of account)  ✓ Within limit
R:R Ratio:   2.1:1  ✓ Meets 2:1 minimum
```

**Validation Icons**:
- ✓ Green checkmark: Criteria met (risk ≤2%, R:R ≥2:1)
- ✗ Red warning: Criteria not met (risk >2%, R:R <2:1)
- ⓘ Info tooltip: Explain why it matters

**Plan Notes Editor**:
- Full markdown editor (same as Journal)
- Support for checklists: `- [ ] Entry criterion`
- Auto-save as you type
- Preview tab

**Actions**:
- **Save as Trade Plan**: Creates `TradePlan` record, sets status to 'active'
- **Clear Form**: Reset all fields

**Form Behavior**:
- Pre-fills with current price if clicked from chart
- Pre-fills with existing entry if "Add to Plan" clicked from Open Entries
- Real-time R:R calculation as user types
- Highlights risk warnings (red) or validation success (green)

---

#### Past Plans Section (Collapsed by default)

```
┌─ PAST PLANS (4) ──────────────────────────────────────┐ [Collapse ▲]
│                                                        │
│ ✅ Executed: Add @ ₹750 (Nov 12, 2024)                │
│    Planned: 60 sh @ ₹750 • Actual: 60 sh @ ₹748       │
│    Variance: ₹2 better • Linked to Trade #47          │
│    [View Trade] [View on Chart]                       │
│                                                        │
│ ───────────────────────────────────────────────────   │
│                                                        │
│ ✅ Executed: Add @ ₹920 (Dec 2, 2024)                 │
│    Planned: 35 sh @ ₹920 • Actual: 35 sh @ ₹920       │
│    Variance: Perfect execution • Linked to Trade #52  │
│    [View Trade] [View on Chart]                       │
│                                                        │
│ ───────────────────────────────────────────────────   │
│                                                        │
│ ✅ Executed: Trim @ ₹1,100 (Dec 15, 2024)             │
│    Planned: 40 sh @ ₹1,100 • Actual: 40 sh @ ₹1,095   │
│    Variance: ₹5 worse • Linked to Trade #56           │
│    [View Trade] [View on Chart]                       │
│                                                        │
│ ───────────────────────────────────────────────────   │
│                                                        │
│ ❌ Cancelled: Add @ ₹800 (Oct 20, 2024)               │
│    Reason: "Price ran away without pullback. Setup    │
│    remained strong but never got entry opportunity."  │
│    [View Analysis]                                    │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Executed Plans** (✅):
- Plan details + Actual execution details
- **Variance Analysis**: Planned ₹1,200 vs Actual ₹1,185 = ₹15 better
- Linked to actual trade record (click to view full trade)
- Green badge: "Perfect execution" or "₹X better/worse"

**Cancelled Plans** (❌):
- Plan details + Cancellation reason
- **Learning Opportunity**: Why didn't it work? (price ran, setup failed, better opportunity)
- Red badge with reason

**Benefits**:
- Learn from execution quality (did I wait for my price?)
- Track discipline (are my plans realistic?)
- Identify patterns (do I cancel too many plans? am I too aggressive/conservative?)

---

## Trade Planning System

### The Planning-First Workflow

```
1. ANALYZE → User sees setup on chart
2. PLAN → Create trade plan with entry criteria
3. WAIT → Plan appears on chart as 📍 marker
4. EXECUTE → Price hits level, trade executed
5. LINK → Auto-suggest or manually link trade to plan
6. LEARN → Review variance, refine future plans
```

### Data Model: `trade_plans` Table

```sql
CREATE TABLE trade_plans (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  position_id BIGINT NOT NULL REFERENCES positions(id) ON DELETE CASCADE,
  security_id BIGINT NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
  trading_account_id BIGINT NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,

  -- Plan Type
  plan_action VARCHAR NOT NULL, -- 'add', 'hold', 'trim', 'close'
  plan_status VARCHAR NOT NULL DEFAULT 'active', -- 'active', 'executed', 'cancelled'

  -- Entry/Exit Details
  planned_entry_price DECIMAL(10,2),
  planned_quantity INTEGER,
  planned_stop_loss DECIMAL(10,2),
  planned_target DECIMAL(10,2),

  -- Risk Management
  risk_amount DECIMAL(10,2), -- ₹ amount risked
  risk_percent DECIMAL(5,2), -- % of account risked
  reward_risk_ratio DECIMAL(5,2), -- Calculated R:R

  -- Plan Notes
  plan_notes TEXT, -- Markdown notes
  plan_notes_html TEXT, -- Rendered HTML
  entry_criteria JSONB, -- Checklist: [{"item": "Price at MA", "checked": false}]

  -- Execution Tracking
  executed_at TIMESTAMP,
  executed_trade_id BIGINT REFERENCES trades(id) ON DELETE SET NULL,
  actual_entry_price DECIMAL(10,2), -- For variance analysis
  actual_quantity INTEGER,
  execution_notes TEXT,

  -- Cancellation Tracking
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_user_position (user_id, position_id),
  INDEX idx_status (plan_status),
  INDEX idx_security (security_id),

  CONSTRAINT valid_plan_action CHECK (plan_action IN ('add', 'hold', 'trim', 'close')),
  CONSTRAINT valid_plan_status CHECK (plan_status IN ('active', 'executed', 'cancelled')),
  CONSTRAINT one_active_per_position UNIQUE (position_id, plan_status) WHERE plan_status = 'active'
);
```

**Key Constraints**:
- **One Active Plan Per Position**: Only 1 active plan allowed (enforced by unique constraint)
- **Valid Actions**: 'add', 'hold', 'trim', 'close'
- **Valid Statuses**: 'active', 'executed', 'cancelled'

---

### Model: `TradePlan`

```ruby
# app/models/trade_plan.rb
class TradePlan < ApplicationRecord
  belongs_to :user
  belongs_to :position
  belongs_to :security
  belongs_to :trading_account
  belongs_to :executed_trade, class_name: 'Trade', foreign_key: 'executed_trade_id', optional: true

  # Enums
  enum plan_action: { add: 'add', hold: 'hold', trim: 'trim', close: 'close' }
  enum plan_status: { active: 'active', executed: 'executed', cancelled: 'cancelled' }

  # Validations
  validates :plan_action, :plan_status, presence: true
  validates :planned_entry_price, :planned_quantity, presence: true, unless: :hold?
  validates :reward_risk_ratio, numericality: { greater_than_or_equal_to: 2 }, if: :add?, message: "Must be at least 2:1"
  validate :one_active_plan_per_position, on: :create

  # Callbacks
  before_save :calculate_risk_reward
  before_save :render_markdown_notes

  # Scopes
  scope :active, -> { where(plan_status: 'active') }
  scope :for_position, ->(position_id) { where(position_id: position_id) }
  scope :executed, -> { where(plan_status: 'executed').order(executed_at: :desc) }
  scope :cancelled, -> { where(plan_status: 'cancelled').order(cancelled_at: :desc) }

  # Instance Methods

  def calculate_risk_reward
    return unless planned_entry_price && planned_stop_loss && planned_target

    risk_per_share = (planned_entry_price - planned_stop_loss).abs
    reward_per_share = (planned_target - planned_entry_price).abs

    self.risk_amount = risk_per_share * planned_quantity
    self.reward_risk_ratio = (reward_per_share / risk_per_share).round(2)

    # Calculate risk % if trading account available
    if trading_account
      account_value = trading_account.total_value
      self.risk_percent = ((risk_amount / account_value) * 100).round(2) if account_value > 0
    end
  end

  def render_markdown_notes
    return unless plan_notes.present?

    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true)
    self.plan_notes_html = markdown.render(plan_notes)
  end

  def execute!(trade)
    update!(
      plan_status: 'executed',
      executed_at: Time.current,
      executed_trade_id: trade.id,
      actual_entry_price: trade.entry_price,
      actual_quantity: trade.quantity
    )
  end

  def cancel!(reason)
    update!(
      plan_status: 'cancelled',
      cancelled_at: Time.current,
      cancellation_reason: reason
    )
  end

  def meets_risk_criteria?
    risk_percent.present? && risk_percent <= 2.0 # Max 2% risk per trade
  end

  def meets_rr_criteria?
    reward_risk_ratio.present? && reward_risk_ratio >= 2.0 # Min 2:1 R:R
  end

  def execution_variance
    return nil unless executed? && actual_entry_price && planned_entry_price

    variance = actual_entry_price - planned_entry_price
    variance_percent = (variance / planned_entry_price * 100).round(2)

    {
      amount: variance,
      percent: variance_percent,
      description: variance.positive? ? "₹#{variance} worse" : "₹#{variance.abs} better"
    }
  end

  private

  def one_active_plan_per_position
    if active? && position.trade_plans.active.where.not(id: id).exists?
      errors.add(:base, "Position already has an active trade plan. Complete or cancel it first.")
    end
  end
end
```

**Key Methods**:
- `calculate_risk_reward`: Auto-calculates risk amount, risk %, and R:R ratio before save
- `execute!(trade)`: Marks plan as executed, links to trade, captures actual execution data
- `cancel!(reason)`: Archives plan with cancellation reason for learning
- `execution_variance`: Compares planned vs actual execution (variance analysis)
- `meets_risk_criteria?`: Validates risk ≤2% of account
- `meets_rr_criteria?`: Validates R:R ≥2:1

---

### User Flow: Planning an Increment (Complete Example)

#### Step 1: User Analyzes Chart

User sees NVDA chart showing:
- Strong uptrend (Stage 2)
- Recent pullback to 10-day moving average
- RS line holding above previous high
- Position already profitable (+41.5%)
- Wants to add to winning position (Minervini principle)

#### Step 2: User Opens Trade Planning Panel

Clicks "📋 TRADE PLANS [Expand ▼]" at bottom of page → Panel expands

#### Step 3: User Fills New Plan Form

```
Action:  [● Add]  [ Hold]  [ Trim]  [ Close]

Entry Price:      [₹1,200]  (Current: ₹1,168)  ← Waiting for slight pullback
Quantity:         [50] shares
Stop Loss:        [₹950]  (-20.8% from entry)
Target:           [₹1,400]  (+16.7% from entry)

Risk Management:
Risk Amount: ₹12,500 (1.0% of account)  ✓ Within 2% limit
R:R Ratio:   1.6:1  ⚠️ Below 2:1 recommended (still allowed)

Plan Notes:
┌────────────────────────────────────────────┐
│ Wait for pullback to 10-day MA (~₹1,200). │
│                                             │
│ Entry criteria:                             │
│ - [ ] Price touches 10-day MA               │
│ - [ ] Volume spike (>40% above 50-day avg) │
│ - [ ] RS line holding above prev high       │
│ - [ ] NIFTY in Stage 2 (supportive market)  │
│                                             │
│ Notes: Only add if ALL 4 criteria met.     │
│ This is 3rd add - position already 6% of   │
│ account, so keep this increment smaller.   │
└────────────────────────────────────────────┘
```

**System Validates**:
- ✓ Entry price reasonable (within 10% of current: ₹1,200 vs ₹1,168 = +2.7%)
- ✓ Risk amount within limit (1.0% < 2% max)
- ⚠️ R:R below 2:1 minimum (1.6:1) - shows warning but allows save
- ✓ All required fields filled

#### Step 4: User Saves Plan

Clicks **[Save as Trade Plan]**

**System Actions**:
1. Creates `TradePlan` record:
   ```ruby
   TradePlan.create!(
     user: current_user,
     position: nvda_position,
     security: nvda_security,
     trading_account: personal_account,
     plan_action: 'add',
     plan_status: 'active',
     planned_entry_price: 1200,
     planned_quantity: 50,
     planned_stop_loss: 950,
     planned_target: 1400,
     risk_amount: 12500, # auto-calculated
     risk_percent: 1.0,  # auto-calculated
     reward_risk_ratio: 1.6, # auto-calculated
     plan_notes: "Wait for pullback to 10-day MA...",
     entry_criteria: [
       { item: "Price touches 10-day MA", checked: false },
       { item: "Volume spike (>40% above 50-day avg)", checked: false },
       { item: "RS line holding above prev high", checked: false },
       { item: "NIFTY in Stage 2 (supportive market)", checked: false }
     ]
   )
   ```

2. Updates UI:
   - Collapsed panel now shows: "Active Plan: Add @ ₹1,200 (50 shares, 1% risk)"
   - Chart adds 📍 marker at ₹1,200 price level
   - New Plan form clears

3. Future: Sets up price alert (when ₹1,200 is reached, notify user)

#### Step 5: Price Approaches Plan Level

Over next 3 days, NVDA pulls back from ₹1,168 to ₹1,195.

**System sends alert** (future feature):
- Email: "NVDA approaching your plan entry at ₹1,200"
- Browser notification: "NVDA @ ₹1,195 - Plan entry ₹1,200"

#### Step 6: User Executes Trade

User checks chart, confirms all 4 entry criteria met, executes in Zerodha:
- Buys 50 shares @ ₹1,185 (got ₹15 better price than planned!)

#### Step 7: Trade Auto-Imports from Zerodha

Background job syncs Zerodha portfolio:
```ruby
# Zerodha sync imports new trade
Trade.create!(
  user: current_user,
  position: nvda_position,
  security: nvda_security,
  trading_account: personal_account,
  trade_type: 'long',
  entry_date: Date.today,
  entry_price: 1185,
  quantity: 50,
  status: 'open'
)
```

#### Step 8: System Auto-Suggests Linking

**Smart Auto-Link Algorithm**:
```ruby
# app/services/trade_plan_matcher.rb
def match_trade_to_plan(trade)
  active_plan = TradePlan.active.for_position(trade.position_id).first
  return nil unless active_plan

  # Check if trade matches plan criteria
  price_match = (trade.entry_price - active_plan.planned_entry_price).abs / active_plan.planned_entry_price < 0.05 # Within 5%
  qty_match = (trade.quantity - active_plan.planned_quantity).abs < 10 # Within 10 shares
  date_match = (trade.entry_date - active_plan.created_at.to_date).days < 30 # Within 30 days

  if price_match && qty_match && date_match
    return active_plan # Strong match
  end
end
```

**Auto-Suggest UI** (toast notification):
```
┌──────────────────────────────────────────────────────────┐
│ 🎯 Trade Imported: NVDA 50 shares @ ₹1,185              │
│                                                           │
│ This matches your active plan (Add @ ₹1,200, 50 shares) │
│ Link this trade to your Dec 1 plan?                     │
│                                                           │
│ [Yes, Link Trade]  [No, Keep Separate]  [View Details]  │
└──────────────────────────────────────────────────────────┘
```

#### Step 9: User Links Trade to Plan

User clicks **[Yes, Link Trade]**

**System Actions**:
1. Calls `active_plan.execute!(trade)`
2. Updates `TradePlan`:
   ```ruby
   plan_status: 'executed'
   executed_at: 2024-12-05 10:30:00
   executed_trade_id: 47
   actual_entry_price: 1185
   actual_quantity: 50
   ```

3. Updates UI:
   - Active Plan section clears (no active plan now)
   - Past Plans section shows new executed plan:
     ```
     ✅ Executed: Add @ ₹1,200 (Dec 5, 2024)
        Planned: 50 sh @ ₹1,200 • Actual: 50 sh @ ₹1,185
        Variance: ₹15 better (Perfect execution!)
        [View Trade] [View on Chart]
     ```
   - Chart marker 📍 changes to 🟢 (executed entry)
   - Open Entries tab shows new entry card:
     ```
     Entry #4 • Dec 5, 2024
     50 shares @ ₹1,185
     Cost: ₹59,250 • Value: ₹58,400 (currently down)
     P&L: -₹850 (-1.4%) ⚠️ (just entered)
     ```

#### Step 10: Learning & Iteration

User can now review:
- **Execution Quality**: Got ₹15 better than planned (1.25% improvement)
- **Plan Accuracy**: All 4 entry criteria were met before executing
- **Discipline**: Waited for planned setup, didn't chase price
- **Future Plans**: This execution data informs next plan (knows they can be patient)

---

### Complete Example: Incremental Position Building

**Scenario**: Building NVDA position over 6 months (Minervini-style)

#### Entry #1 (Initial Position) - Jul 5, 2024
- **Setup**: Stage 2 breakout, pocket pivot
- **Plan**: Buy 90 shares @ ₹730, stop ₹670, target ₹850
- **Execution**: Bought 90 @ ₹730 (perfect)
- **Risk**: 2% of account (₹6,000 risk ÷ ₹60/share = 90 shares)
- **Result**: 🟢 Entry #1 on chart

#### Entry #2 (First Add) - Nov 12, 2024
- **Setup**: Stock up 35%, pullback to 10-day MA, RS new high
- **Plan**: Add 60 shares @ ₹750, stop ₹680, target ₹950
- **Execution**: Bought 60 @ ₹748 (₹2 better)
- **Risk**: 1.5% of account (smaller add, already have base)
- **Stop Raised**: From ₹670 → ₹680 (protecting Entry #1)
- **Result**: 🟢 Entry #2 on chart, position now 150 shares @ avg ₹740

#### Entry #3 (Second Add) - Dec 2, 2024
- **Setup**: Stock up another 25%, still Stage 2, another pullback
- **Plan**: Add 35 shares @ ₹920, stop ₹850, target ₹1,050
- **Execution**: Bought 35 @ ₹920 (perfect)
- **Risk**: 1% of account (position now large, final add)
- **Stop Raised**: From ₹680 → ₹850 (all entries now protected)
- **Result**: 🟢 Entry #3 on chart, position now 185 shares @ avg ₹800

#### Exit #1 (Partial Profit) - Dec 15, 2024
- **Setup**: Hit first target ₹1,100, take some chips off table
- **Plan**: Trim 40 shares @ ₹1,100, trail stop on remainder
- **Execution**: Sold 40 @ ₹1,095 (₹5 worse, still great)
- **Profit**: ₹12,000 on trimmed shares (+37% avg gain)
- **Result**: 🔴 Exit #1 on chart, position now 145 shares

#### Current State - Dec 20, 2024
- **Position**: 145 shares @ avg ₹825 (after trim)
- **Current Price**: ₹1,168
- **Unrealized P&L**: +₹49,692 (+41.5%)
- **Open Entries**:
  - Entry #1: 90 sh @ ₹730 → +60.0% 🔥
  - Entry #2: 60 sh @ ₹750 → +55.7% 🔥
  - Entry #3: 35 sh @ ₹920 → +26.9% ✅
- **Closed**: Exit #1: 40 sh profit ₹12,000
- **Active Plan**: Add @ ₹1,200 if pulls back (50 shares planned)

**Chart Shows**:
```
NVDA Position Timeline:
    ₹1,200 ┤                             📍 ← Planned Add #4
           │                       🎯 ← Trim Target (₹1,400)
    ₹1,100 ├─────────────────🔴──────
           │              Exit #1 (@₹1,095)
      ₹920 ├──────────🟢────────────
           │      Entry #3 (@₹920)
      ₹850 ├────🟢────────────────
           │ Entry #2 (@₹748)
      ₹730 ├🟢─────────────────────
           │Entry #1 (@₹730)
      ₹600 └──────────────────────
           Jul   Aug   Sep   Oct   Nov   Dec
```

**Right Sidebar Shows**:
```
Open Entries (3):
• Entry #1: 90 sh @ ₹730 → ₹1,168 (+60.0%)
• Entry #2: 60 sh @ ₹750 → ₹1,168 (+55.7%)
• Entry #3: 35 sh @ ₹920 → ₹1,168 (+26.9%)

Total: 145 sh @ avg ₹825 → ₹1,168 (+41.5%)

Closed Trades (1):
• Exit #1: 40 sh @ ₹1,095 (Profit: +₹12,000)
```

**Trade Planning Panel Shows**:
```
Active Plan: Add @ ₹1,200 (50 shares, 1% risk)

Past Plans (4):
✅ Add @ ₹750 (Nov 12) - Variance: ₹2 better
✅ Add @ ₹920 (Dec 2) - Perfect execution
✅ Trim @ ₹1,100 (Dec 15) - Variance: ₹5 worse
❌ Add @ ₹800 (Oct 20) - Cancelled: Price ran away
```

**Key Benefits Demonstrated**:
1. **Full History**: See every entry/exit decision on one chart
2. **Plan vs Reality**: Compare every planned vs actual execution
3. **Learning**: Cancelled plan @ ₹800 shows missed opportunity (would've been Entry #2.5)
4. **Risk Control**: Each add progressively smaller, stops raised
5. **Discipline**: Pre-planned exits prevent emotional selling
6. **Incremental Mindset**: Started small (90 sh), scaled up as trade worked (60 → 35)
7. **Profit Protection**: Trimmed 40 shares at ₹1,100, locked in ₹12K
8. **Patience**: Waiting for ₹1,200 pullback, not chasing current price

---

## Data Models

### Enhancements to Existing Tables

#### `positions` Table - New Columns

```ruby
# Migration: AddPositionManagementFieldsToPositions
class AddPositionManagementFieldsToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :stop_loss, :decimal, precision: 10, scale: 2
    add_column :positions, :take_profit, :decimal, precision: 10, scale: 2
    add_column :positions, :entry_price, :decimal, precision: 10, scale: 2 # If not exists
    add_column :positions, :sentiment_tag, :string # 'buy', 'sell', 'hold', null
    add_column :positions, :status, :string, default: 'open' # 'open', 'closed'
  end
end
```

#### `Position` Model - New Methods

```ruby
# app/models/position.rb
class Position < ApplicationRecord
  belongs_to :holding_section, optional: true
  belongs_to :trading_account
  belongs_to :security
  has_many :trades
  has_many :trade_plans

  # Portfolio metrics
  def portfolio_weight_percent(total_portfolio_value)
    return 0 if total_portfolio_value.zero?
    (current_value / total_portfolio_value * 100).round(1)
  end

  def unrealized_pnl
    current_value - total_cost
  end

  def unrealized_pnl_percent
    return 0 if total_cost.zero?
    ((current_value - total_cost) / total_cost * 100).round(2)
  end

  def day_change
    return 0 unless security.yesterday_close
    (security.last_price - security.yesterday_close) * quantity
  end

  def day_change_percent
    return 0 unless security.yesterday_close
    ((security.last_price - security.yesterday_close) / security.yesterday_close * 100).round(2)
  end

  # Risk metrics
  def risk_amount
    return 0 unless stop_loss
    (entry_price - stop_loss) * quantity
  end

  def risk_percent_of_account(account_total)
    return 0 if account_total.zero?
    (risk_amount / account_total * 100).round(2)
  end

  def risk_level
    weight = portfolio_weight_percent(trading_account.total_value)
    if weight > 15
      'high'
    elsif weight > 10
      'medium'
    else
      'normal'
    end
  end

  # Values
  def current_value
    security.last_price * quantity
  end

  def total_cost
    average_price * quantity
  end

  # Incremental entries
  def incremental_entries
    trades.where(status: 'open', trade_type: 'long').order(entry_date: :asc)
  end

  def active_plan
    trade_plans.active.first
  end
end
```

---

## Implementation Details

### Controller: `PositionsController`

```ruby
# app/controllers/positions_controller.rb
class PositionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_position, only: [:show, :update, :destroy]

  def index
    @account = selected_account
    @positions = @account.positions
                         .includes(:security, :holding_section, :trades, :trade_plans)
                         .order('holding_sections.position ASC, positions.created_at DESC')

    # Filter by status (Open/All)
    @positions = @positions.where(status: 'open') if params[:filter] == 'open'

    # Group by holding sections
    @sections = HoldingSection.where(user: current_user)
                               .includes(:positions)
                               .order(position: :asc)

    # Selected position (from URL param or first position)
    @selected_position = @positions.find_by(id: params[:selected_id]) || @positions.first

    # Position detail data
    if @selected_position
      @chart_data = fetch_chart_data(@selected_position, params[:period] || '1Y')
      @open_entries = @selected_position.incremental_entries
      @closed_trades = @selected_position.trades.where(status: 'closed').order(exit_date: :desc)
      @position_notes = JournalEntry.for_security(@selected_position.security_id)
                                     .where(entry_type: 'watchlist_note')
                                     .order(created_at: :desc)
      @active_plan = @selected_position.active_plan
      @past_plans = @selected_position.trade_plans.where.not(plan_status: 'active')
                                       .order(created_at: :desc)
    end

    # Portfolio stats
    @portfolio_stats = calculate_portfolio_stats(@account)
  end

  private

  def selected_account
    if params[:account_id].present?
      current_user.trading_accounts.find(params[:account_id])
    else
      current_user.trading_accounts.where(is_primary: true).first ||
      current_user.trading_accounts.first
    end
  end

  def fetch_chart_data(position, period)
    security = position.security
    price_history = security.price_updates.for_period(period)
    trades_in_period = position.trades.within_period(period)
    plans_in_period = position.trade_plans.where('created_at >= ?', period_start_date(period))

    {
      dates: price_history.map(&:date),
      prices: price_history.map(&:close_price),
      avg_cost: position.average_price,
      stop_loss: position.stop_loss,
      buy_orders: trades_in_period.where(trade_type: 'long').map { |t|
        { date: t.entry_date, price: t.entry_price, qty: t.quantity, id: t.id }
      },
      sell_orders: trades_in_period.where(trade_type: 'short').or(
        trades_in_period.where(status: 'closed')
      ).map { |t|
        { date: t.exit_date || t.entry_date, price: t.exit_price || t.entry_price, qty: t.quantity, id: t.id }
      },
      planned_entries: plans_in_period.where(plan_action: ['add', 'close']).map { |p|
        {
          date: p.created_at.to_date,
          price: p.planned_entry_price,
          qty: p.planned_quantity,
          status: p.plan_status,
          id: p.id
        }
      },
      planned_targets: plans_in_period.where.not(planned_target: nil).map { |p|
        {
          date: p.created_at.to_date,
          price: p.planned_target,
          status: p.plan_status,
          id: p.id
        }
      }
    }
  end

  def calculate_portfolio_stats(account)
    total_value = account.positions.sum(&:current_value)
    total_cost = account.positions.sum(&:total_cost)
    unrealized_pnl = total_value - total_cost

    {
      total_value: total_value,
      total_cost: total_cost,
      unrealized_pnl: unrealized_pnl,
      unrealized_pnl_percent: total_cost.zero? ? 0 : (unrealized_pnl / total_cost * 100).round(2)
    }
  end

  def period_start_date(period)
    case period
    when '1D' then 1.day.ago
    when '1W' then 1.week.ago
    when '1M' then 1.month.ago
    when '3M' then 3.months.ago
    when '6M' then 6.months.ago
    when '1Y' then 1.year.ago
    else 10.years.ago # ALL
    end
  end
end
```

---

### Controller: `TradePlansController`

```ruby
# app/controllers/trade_plans_controller.rb
class TradePlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_position
  before_action :set_trade_plan, only: [:edit, :update, :execute, :cancel]

  def create
    @trade_plan = @position.trade_plans.build(trade_plan_params)
    @trade_plan.user = current_user
    @trade_plan.security = @position.security
    @trade_plan.trading_account = @position.trading_account

    if @trade_plan.save
      redirect_to positions_path(selected_id: @position.id),
                  notice: 'Trade plan created successfully. Plan added to chart.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def execute
    trade = find_or_create_trade(params[:trade_id])

    if trade && @trade_plan.execute!(trade)
      redirect_to positions_path(selected_id: @position.id),
                  notice: 'Plan marked as executed and linked to trade.'
    else
      redirect_to positions_path(selected_id: @position.id),
                  alert: 'Failed to execute plan.'
    end
  end

  def cancel
    if @trade_plan.cancel!(params[:cancellation_reason])
      redirect_to positions_path(selected_id: @position.id),
                  notice: 'Plan cancelled and archived for learning.'
    else
      redirect_to positions_path(selected_id: @position.id),
                  alert: 'Failed to cancel plan.'
    end
  end

  private

  def set_position
    @position = current_user.positions.find(params[:position_id])
  end

  def set_trade_plan
    @trade_plan = @position.trade_plans.find(params[:id])
  end

  def trade_plan_params
    params.require(:trade_plan).permit(
      :plan_action, :planned_entry_price, :planned_quantity,
      :planned_stop_loss, :planned_target, :plan_notes,
      entry_criteria: [:item, :checked]
    )
  end

  def find_or_create_trade(trade_id)
    if trade_id.present?
      @position.trades.find(trade_id)
    else
      # Create new trade from plan
      @position.trades.create!(
        user: current_user,
        security: @position.security,
        trading_account: @position.trading_account,
        trade_type: @trade_plan.plan_action == 'close' ? 'short' : 'long',
        entry_date: Date.today,
        entry_price: params[:actual_entry_price] || @trade_plan.planned_entry_price,
        quantity: params[:actual_quantity] || @trade_plan.planned_quantity,
        status: 'open'
      )
    end
  end
end
```

---

### Stimulus Controllers

#### 1. Chart Controller (Chart.js with Plans)

```javascript
// app/javascript/controllers/chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static values = { data: Object }

  connect() {
    this.renderChart()
  }

  renderChart() {
    const ctx = document.getElementById('position-chart').getContext('2d')
    const chartData = this.dataValue

    // Prepare datasets
    const datasets = [
      // Price line
      {
        label: 'Price',
        data: chartData.prices,
        borderColor: '#00A63E',
        backgroundColor: 'rgba(0, 166, 62, 0.1)',
        fill: true,
        tension: 0.3,
        pointRadius: 0
      }
    ]

    // Add avg cost line if present
    if (chartData.avg_cost) {
      datasets.push({
        label: 'Avg Cost',
        data: Array(chartData.dates.length).fill(chartData.avg_cost),
        borderColor: '#717182',
        borderDash: [5, 5],
        borderWidth: 2,
        pointRadius: 0,
        fill: false
      })
    }

    // Add stop loss line if present
    if (chartData.stop_loss) {
      datasets.push({
        label: 'Stop Loss',
        data: Array(chartData.dates.length).fill(chartData.stop_loss),
        borderColor: '#E7000B',
        borderDash: [3, 3],
        borderWidth: 2,
        pointRadius: 0,
        fill: false
      })
    }

    // Add buy order markers
    if (chartData.buy_orders && chartData.buy_orders.length > 0) {
      datasets.push({
        label: 'Buy Orders',
        data: chartData.buy_orders.map(o => ({ x: o.date, y: o.price })),
        type: 'scatter',
        backgroundColor: '#00A63E',
        borderColor: '#00A63E',
        pointRadius: (context) => {
          // Bubble size based on qty
          const order = chartData.buy_orders[context.dataIndex]
          return order ? Math.max(6, Math.min(12, order.qty / 10)) : 6
        },
        pointHoverRadius: 10
      })
    }

    // Add sell order markers
    if (chartData.sell_orders && chartData.sell_orders.length > 0) {
      datasets.push({
        label: 'Sell Orders',
        data: chartData.sell_orders.map(o => ({ x: o.date, y: o.price })),
        type: 'scatter',
        backgroundColor: '#E7000B',
        borderColor: '#E7000B',
        pointRadius: (context) => {
          const order = chartData.sell_orders[context.dataIndex]
          return order ? Math.max(6, Math.min(12, order.qty / 10)) : 6
        },
        pointHoverRadius: 10
      })
    }

    // Add planned entry markers (📍)
    if (chartData.planned_entries && chartData.planned_entries.length > 0) {
      datasets.push({
        label: 'Planned Entries',
        data: chartData.planned_entries.map(p => ({ x: p.date, y: p.price })),
        type: 'scatter',
        backgroundColor: p => p.raw.status === 'executed' ? '#00A63E' : '#3B82F6',
        borderColor: p => p.raw.status === 'executed' ? '#00A63E' : '#3B82F6',
        pointStyle: 'triangle',
        pointRadius: 8,
        pointHoverRadius: 10
      })
    }

    // Render chart
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: chartData.dates,
        datasets: datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'nearest',
          intersect: true
        },
        plugins: {
          tooltip: {
            callbacks: {
              title: function(context) {
                return context[0].label
              },
              label: function(context) {
                const label = context.dataset.label || ''
                const value = context.parsed.y

                // Custom tooltip for buy/sell orders
                if (label === 'Buy Orders' || label === 'Sell Orders') {
                  const order = label === 'Buy Orders' ?
                    chartData.buy_orders[context.dataIndex] :
                    chartData.sell_orders[context.dataIndex]

                  if (order) {
                    return `${label}: ${order.qty} shares @ ₹${value.toFixed(2)}`
                  }
                }

                return `${label}: ₹${value.toFixed(2)}`
              }
            }
          },
          legend: {
            display: true,
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 15
            }
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            ticks: {
              callback: function(value) {
                return '₹' + value.toFixed(0)
              }
            }
          },
          x: {
            type: 'time',
            time: {
              unit: 'month'
            }
          }
        }
      }
    })
  }
}
```

---

#### 2. Trading Calculator Controller

```javascript
// app/javascript/controllers/trading_calculator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "portfolioValue", "riskPercent", "entryPrice", "stopLoss",
    "quantity", "riskPerShare", "totalRisk", "rrRatio"
  ]

  connect() {
    this.calculate()
  }

  calculate() {
    const portfolioValue = parseFloat(this.portfolioValueTarget.value) || 0
    const riskPercent = parseFloat(this.riskPercentTarget.value) || 2
    const entryPrice = parseFloat(this.entryPriceTarget.value) || 0
    const stopLoss = parseFloat(this.stopLossTarget.value) || 0
    const target = parseFloat(this.targetTarget?.value) || 0

    if (entryPrice <= 0 || stopLoss <= 0) {
      return
    }

    const riskAmount = portfolioValue * (riskPercent / 100)
    const riskPerShare = entryPrice - stopLoss
    const positionSize = Math.floor(riskAmount / riskPerShare)
    const totalRisk = positionSize * riskPerShare

    // Update displays
    this.quantityTarget.textContent = positionSize
    this.riskPerShareTarget.textContent = `₹${riskPerShare.toFixed(2)}`
    this.totalRiskTarget.textContent = `₹${totalRisk.toFixed(0)}`

    // Calculate R:R if target provided
    if (target > 0 && this.rrRatioTarget) {
      const rewardPerShare = target - entryPrice
      const rrRatio = (rewardPerShare / riskPerShare).toFixed(1)
      this.rrRatioTarget.textContent = `${rrRatio}:1`

      // Highlight R:R validation
      if (rrRatio >= 2.0) {
        this.rrRatioTarget.classList.add('text-green-600')
        this.rrRatioTarget.classList.remove('text-red-600')
      } else {
        this.rrRatioTarget.classList.add('text-red-600')
        this.rrRatioTarget.classList.remove('text-green-600')
      }
    }

    // Highlight risk level
    const riskPercentOfAccount = (totalRisk / portfolioValue * 100)
    if (riskPercentOfAccount > 2) {
      this.totalRiskTarget.classList.add('text-red-600')
      this.totalRiskTarget.classList.remove('text-green-600')
    } else {
      this.totalRiskTarget.classList.add('text-green-600')
      this.totalRiskTarget.classList.remove('text-red-600')
    }
  }
}
```

---

#### 3. Collapsible Controller (Sections & Trade Planning Panel)

```javascript
// app/javascript/controllers/collapsible_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "trigger"]

  toggle() {
    const isCollapsed = this.contentTarget.classList.toggle("hidden")

    // Update icon
    if (this.hasIconTarget) {
      this.iconTarget.textContent = isCollapsed ? "+" : "−"
    }

    // Update trigger text if present
    if (this.hasTriggerTarget) {
      const currentText = this.triggerTarget.textContent
      this.triggerTarget.textContent = currentText.includes("Expand") ?
        currentText.replace("Expand ▼", "Collapse ▲") :
        currentText.replace("Collapse ▲", "Expand ▼")
    }

    // Save state to preferences (for position sections)
    if (this.element.dataset.sectionName) {
      this.saveState(this.element.dataset.sectionName, isCollapsed)
    }
  }

  saveState(sectionName, isCollapsed) {
    fetch(`/preferences/dashboard/collapsed_sections/nested`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ section: sectionName, collapsed: isCollapsed })
    })
  }
}
```

---

### View Structure

```erb
<!-- app/views/positions/index.html.erb -->

<div class="positions-page">
  <%= render 'shared/topbar', account: @account %>

  <div class="positions-layout">
    <!-- LEFT: Position Sidebar -->
    <aside class="positions-sidebar">
      <div class="sidebar-header">
        <h2>Positions</h2>
        <%= link_to positions_path(filter: params[:filter] == 'open' ? 'all' : 'open'),
                    class: "filter-btn" do %>
          <%= params[:filter] == 'open' ? 'All' : 'Open' %>
        <% end %>
      </div>

      <% @sections.each do |section| %>
        <%= render 'positions/section',
                   section: section,
                   selected_position: @selected_position,
                   portfolio_total: @portfolio_stats[:total_value] %>
      <% end %>
    </aside>

    <!-- CENTER: Chart Hero + Metrics Row -->
    <main class="positions-main">
      <% if @selected_position %>
        <!-- Chart Section (600px height) -->
        <%= render 'positions/chart',
                   position: @selected_position,
                   chart_data: @chart_data %>

        <!-- Position Metrics Row (horizontal, 80px) -->
        <%= render 'positions/metrics_row',
                   position: @selected_position,
                   portfolio_stats: @portfolio_stats %>

        <!-- Trade Planning Panel (collapsible) -->
        <%= render 'positions/trade_planning_panel',
                   position: @selected_position,
                   active_plan: @active_plan,
                   past_plans: @past_plans %>
      <% else %>
        <div class="empty-state">
          <p>No positions found. Add your first position to get started.</p>
        </div>
      <% end %>
    </main>

    <!-- RIGHT: Trades & Notes Sidebar -->
    <aside class="notes-sidebar">
      <%= render 'positions/notes_sidebar',
                 position: @selected_position,
                 open_entries: @open_entries,
                 closed_trades: @closed_trades,
                 notes: @position_notes %>
    </aside>
  </div>
</div>
```

---

## Typography System

**Font Family**: Arimo (Google Font)
**Weights**: 400 (Regular), 600 (Semibold)

**Font Sizes**:
- **32px**: Large numbers (current price display)
- **18px**: Page headings ("Positions", "NVDA")
- **16px**: Section headings ("Position Management", "Trade Plans")
- **14px**: Body text, table values, labels, buttons
- **12px**: Small text, column headers, tags, notes metadata

**Line Heights**:
- 32px → 32px (100%)
- 18px → 28px (156%)
- 16px → 24px (150%)
- 14px → 20px (143%)
- 12px → 16px (133%)

**Text Colors**:
- **Primary**: #0A0A0A (near black)
- **Secondary**: #717182 (blue-gray)
- **Tertiary**: #4A5565 (darker gray)
- **Success**: #00A63E (green) / #008236 (dark green for badges)
- **Destructive**: #E7000B (red) / #C10007 (dark red for badges)
- **Warning**: #F59E0B (yellow/orange)

---

## Color Palette

**Backgrounds**:
- Page: #F9FAFB (gray-50)
- Card/Sidebar: #FFFFFF (white)
- Selected row: #EFF6FF (blue-50)
- Button inactive: #F3F4F6 (gray-100)
- Note cards: #F9FAFB (gray-50)

**Borders**:
- Primary: #E5E7EB (gray-200)
- Selected: #BEDBFF (blue-200)
- Section separator: #F3F4F6 (gray-100)

**Status Colors**:
- **Positive** (gains): #00A63E
- **Negative** (losses): #E7000B
- **Selected/Active**: #3B82F6 (blue-500)
- **Buy badge**: #DCFCE7 bg, #008236 text
- **Sell badge**: #FFE2E2 bg, #C10007 text
- **Market badge**: #FFF3CD bg, #F59E0B text
- **High Risk badge**: #FFE2E2 bg, #C10007 text
- **Normal Risk badge**: #DCFCE7 bg, #008236 text

**Shadows**:
- Card shadow: `0px 1px 3px rgba(0, 0, 0, 0.1)`
- Subtle, almost flat design

---

## Implementation Checklist

### Phase 1: Chart Hero + Metrics Row (Week 1-2)
- [ ] Expand chart section height to 600px
- [ ] Implement Chart.js with historical price data
- [ ] Add avg cost line (dashed gray) to chart
- [ ] Add stop loss line (dashed red) to chart
- [ ] Redesign metrics as horizontal 2-row grid
- [ ] Add inline edit modal for stop/target values
- [ ] Implement chart overlays toggle (show/hide lines)
- [ ] Add time period filters (1D, 1W, 1M, 3M, 6M, 1Y, ALL)

### Phase 2: Trade Planning Infrastructure (Week 3-4)
- [ ] Create `trade_plans` table migration
- [ ] Build `TradePlan` model with validations
- [ ] Create `TradePlansController` with CRUD actions
- [ ] Build Trade Planning Panel UI (collapsible)
- [ ] Implement New Plan form with real-time R:R calculation
- [ ] Add Active Plan display section
- [ ] Create Past Plans section (collapsed by default)

### Phase 3: Plan Execution & Linking (Week 5)
- [ ] Build "Mark Executed" workflow
- [ ] Implement plan → trade linking (manual modal)
- [ ] Create "Link to existing trade" selection modal
- [ ] Add execution variance calculation and display
- [ ] Show planned entry markers on chart (📍 triangle icons)
- [ ] Change marker to 🟢 when plan executed
- [ ] Add planned target markers (🎯) to chart

### Phase 4: Smart Auto-Linking (Week 6)
- [ ] Build `TradePlanMatcher` service
- [ ] Implement trade import detection (after Zerodha sync)
- [ ] Create "match trade to plan" algorithm
- [ ] Build auto-suggest toast notification UI
- [ ] Add one-click plan linking from notification
- [ ] Update chart markers on link (📍 → 🟢)

### Phase 5: Incremental Entries UI (Week 7)
- [ ] Redesign Open Entries tab with separate entry cards
- [ ] Show individual P&L per entry
- [ ] Add "View on Chart" action (highlight specific marker)
- [ ] Add "Add to Plan" quick action (pre-fill plan form)
- [ ] Calculate and display pyramid summary stats
- [ ] Style entry cards with background, padding, spacing

### Phase 6: Polish & Mobile (Week 8)
- [ ] Add keyboard shortcuts (N = new plan, E = edit plan)
- [ ] Implement responsive design for tablet/mobile
- [ ] Mobile: Chart reduces to 300px, metrics stack vertically
- [ ] Mobile: Trade planning panel becomes bottom sheet
- [ ] Add loading states and skeleton screens
- [ ] Polish animations and transitions
- [ ] User acceptance testing
- [ ] Performance optimization (lazy load past plans)

---

## Success Metrics

### Adoption Metrics
- **% Users Creating Plans**: Target 60%+ of active traders create ≥1 plan/week
- **Plan Execution Rate**: Target 40%+ of plans get executed (vs cancelled)
- **Plan Accuracy**: Avg execution variance <5% (planned vs actual)

### Behavioral Metrics
- **Incremental Position Adoption**: Target 30%+ users manage positions with ≥2 entries
- **Risk Discipline**: 80%+ of plans meet 2:1 R:R minimum
- **Pre-Planning Rate**: 50%+ of trades have linked pre-plan (vs impulsive trades)

### Outcome Metrics
- **Planned Trade Performance**: Compare R-multiple of planned trades vs unplanned
- **Hypothesis**: Planned trades should have higher avg R (2.5R vs 1.5R unplanned)
- **Position Management**: Users with incremental plans should have lower max drawdown

---

## Next Steps

1. **Start with Phase 1**: Chart hero expansion + horizontal metrics row (quick visual wins)
2. **Build Planning Infrastructure**: Complete Phases 2-3 for core planning workflow
3. **Add Smart Features**: Phases 4-5 for auto-linking and incremental management
4. **Polish & Ship**: Phase 6 for production readiness

**Recommended First Task**: Expand chart to 600px and implement horizontal metrics row. This gives immediate visual impact and validates the chart-hero philosophy before investing in complex planning features.

---

**End of Consolidated Specification**
