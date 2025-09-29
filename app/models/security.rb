class Security < ApplicationRecord
  # Note: Securities are global data, NOT tenant-scoped
  # This allows sharing market data across all users efficiently

  # Associations
  has_many :user_stock_analyses, dependent: :destroy
  has_many :trades, dependent: :restrict_with_error
  has_many :positions, dependent: :restrict_with_error

  # Validations
  validates :symbol, presence: true
  validates :company_name, presence: true
  validates :exchange, presence: true
  validates :security_type, presence: true
  validates :symbol, uniqueness: { scope: :exchange }

  # Enums
  enum :security_type, {
    stock: "stock",
    future: "future",
    option: "option",
    etf: "etf",
    mutual_fund: "mutual_fund",
    currency: "currency",
    commodity: "commodity"
  }, default: :stock

  # Scopes
  scope :active, -> { where(active: true) }
  scope :stocks, -> { where(security_type: :stock) }
  scope :nse, -> { where(exchange: 'NSE') }
  scope :bse, -> { where(exchange: 'BSE') }
  scope :by_sector, ->(sector) { where(sector: sector) }
  scope :recently_updated, -> { where('last_updated > ?', 1.hour.ago) }

  # Search functionality
  scope :search, ->(term) {
    where(
      "symbol ILIKE ? OR company_name ILIKE ? OR nse_symbol ILIKE ?",
      "%#{term}%", "%#{term}%", "%#{term}%"
    )
  }

  # Market data methods
  def price_change_positive?
    day_change.to_f > 0
  end

  def price_change_negative?
    day_change.to_f < 0
  end

  def display_symbol
    nse_symbol.presence || symbol
  end

  def market_cap_in_crores
    return nil unless market_cap.present?
    (market_cap / 10_000_000).round(2)
  end

  def volume_ratio
    return nil unless volume.present? && avg_volume.present? && avg_volume > 0
    (volume.to_f / avg_volume).round(2)
  end

  def near_52_week_high?
    return false unless last_price.present? && week_52_high.present?
    (last_price / week_52_high) > 0.85
  end

  def near_52_week_low?
    return false unless last_price.present? && week_52_low.present?
    (last_price / week_52_low) < 1.15
  end

  # User-specific analysis (for a given user)
  def analysis_for_user(user)
    user_stock_analyses.find_by(user: user)
  end

  def stage_for_user(user)
    analysis_for_user(user)&.user_stage
  end

  def rs_rank_for_user(user)
    analysis_for_user(user)&.user_rs_rank
  end

  def notes_for_user(user)
    analysis_for_user(user)&.user_notes
  end

  # Data sync methods
  def update_market_data!(price_data)
    update!(
      last_price: price_data[:last_price],
      day_change: price_data[:day_change],
      day_change_percent: price_data[:day_change_percent],
      volume: price_data[:volume],
      last_updated: Time.current
    )
  end

  def stale_data?
    last_updated.nil? || last_updated < 1.hour.ago
  end

  def self.sync_market_data_for_active_securities
    # Called by background job to update prices for all actively traded securities
    active_symbols = joins(:trades)
      .where(trades: { status: 'open' })
      .distinct
      .pluck(:symbol)

    # TODO: Implement Zerodha API bulk price fetch
    # ZerodhaMarketDataService.bulk_fetch_prices(active_symbols)
  end

  # Display helpers
  def formatted_price
    return "₹--" unless last_price.present?
    "₹#{last_price.to_f.round(2)}"
  end

  def formatted_change
    return "--" unless day_change.present?
    change = day_change.to_f.round(2)
    sign = change >= 0 ? "+" : ""
    "#{sign}₹#{change}"
  end

  def formatted_change_percent
    return "--" unless day_change_percent.present?
    percent = day_change_percent.to_f.round(2)
    sign = percent >= 0 ? "+" : ""
    "#{sign}#{percent}%"
  end

  def change_color_class
    return "text-gray-500" unless day_change.present?
    day_change.to_f >= 0 ? "text-green-600" : "text-red-600"
  end
end