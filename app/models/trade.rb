class Trade < ApplicationRecord
  acts_as_tenant(:user)

  # Associations
  belongs_to :user
  belongs_to :trading_account
  belongs_to :security
  has_one :journal_entry, dependent: :destroy

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :entry_price, presence: true, numericality: { greater_than: 0 }
  validates :entry_date, presence: true
  validates :exit_price, presence: true, numericality: { greater_than: 0 }, if: :closed?
  validates :exit_date, presence: true, if: :closed?
  validates :trade_type, presence: true
  validates :timeframe, presence: true
  validates :status, presence: true

  # Enums
  enum :trade_type, { buy: "buy", sell: "sell" }, default: :buy
  enum :timeframe, {
    intraday: "intraday",
    swing: "swing",
    positional: "positional",
    long_term: "long_term"
  }, default: :swing
  enum :status, { open: "open", closed: "closed", partial: "partial" }, default: :open

  # Scopes
  scope :recent, -> { order(entry_date: :desc) }
  scope :profitable, -> { where('net_pnl > 0') }
  scope :losing, -> { where('net_pnl < 0') }
  scope :by_strategy, ->(strategy) { where(strategy: strategy) }
  scope :by_timeframe, ->(tf) { where(timeframe: tf) }
  scope :this_month, -> { where(entry_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :this_year, -> { where(entry_date: Date.current.beginning_of_year..Date.current.end_of_year) }

  # Callbacks
  before_save :calculate_pnl, if: :should_calculate_pnl?
  before_save :calculate_risk_reward, if: :has_risk_levels?
  after_update :update_account_snapshot, if: :saved_change_to_status?

  # P&L Calculations
  def calculate_pnl
    return unless exit_price.present? && quantity.present? && entry_price.present?

    self.gross_pnl = case trade_type
    when "buy"
      (exit_price - entry_price) * quantity
    when "sell"
      (entry_price - exit_price) * quantity
    end

    self.net_pnl = gross_pnl - (brokerage || 0) - (taxes || 0)
  end

  def calculate_risk_reward
    return unless planned_stop_loss.present? && planned_target.present? && entry_price.present?

    risk = (entry_price - planned_stop_loss).abs
    reward = (planned_target - entry_price).abs

    self.risk_reward_ratio = risk > 0 ? (reward / risk).round(2) : 0
  end

  # Trade Analysis
  def profitable?
    net_pnl.present? && net_pnl > 0
  end

  def losing?
    net_pnl.present? && net_pnl < 0
  end

  def breakeven?
    net_pnl.present? && net_pnl.abs < 10 # Within ₹10 of breakeven
  end

  def days_held
    return 0 unless entry_date.present?
    end_date = exit_date || Date.current
    (end_date.to_date - entry_date.to_date).to_i
  end

  def annualized_return
    return 0 unless closed? && profitable? && days_held > 0

    investment = entry_price * quantity
    return 0 if investment.zero?

    daily_return = (net_pnl / investment)
    ((1 + daily_return) ** (365.0 / days_held) - 1) * 100
  end

  # Risk Metrics
  def risk_amount_actual
    return 0 unless entry_price.present? && planned_stop_loss.present? && quantity.present?
    (entry_price - planned_stop_loss).abs * quantity
  end

  def position_value
    entry_price * quantity
  end

  def current_value
    return position_value unless security.last_price.present?
    security.last_price * quantity
  end

  def unrealized_pnl
    return 0 if closed?
    return 0 unless security.last_price.present?

    case trade_type
    when "buy"
      (security.last_price - entry_price) * quantity
    when "sell"
      (entry_price - security.last_price) * quantity
    end
  end

  def unrealized_pnl_percent
    return 0 if position_value.zero?
    (unrealized_pnl / position_value * 100).round(2)
  end

  # R-Multiple calculation (how many times initial risk was gained/lost)
  def r_multiple
    return 0 unless risk_amount.present? && risk_amount > 0 && net_pnl.present?
    (net_pnl / risk_amount).round(2)
  end

  # Stage Analysis at Entry
  def stage_at_entry
    entry_stage || security.stage_for_user(user)
  end

  def rs_at_entry
    entry_rs_rank || security.rs_rank_for_user(user)
  end

  # Display Methods
  def formatted_pnl
    return "₹--" unless net_pnl.present?
    pnl = net_pnl.to_f
    sign = pnl >= 0 ? "+" : ""
    "#{sign}₹#{pnl.round(2)}"
  end

  def formatted_unrealized_pnl
    return "₹--" unless open?
    pnl = unrealized_pnl.to_f
    sign = pnl >= 0 ? "+" : ""
    "#{sign}₹#{pnl.round(2)}"
  end

  def pnl_color_class
    pnl_value = closed? ? net_pnl : unrealized_pnl
    return "text-gray-500" unless pnl_value.present?
    pnl_value >= 0 ? "text-green-600" : "text-red-600"
  end

  def strategy_display
    strategy&.humanize || "Unclassified"
  end

  def timeframe_display
    timeframe.humanize
  end

  # Quick creation methods
  def self.create_from_zerodha_data(user, account, zerodha_trade_data)
    # TODO: Implement when Zerodha integration is ready
    # Parse zerodha trade data and create trade record
  end

  private

    def should_calculate_pnl?
      (exit_price_changed? || quantity_changed? || entry_price_changed?) && closed?
    end

    def has_risk_levels?
      planned_stop_loss.present? && planned_target.present? && entry_price.present?
    end

    def update_account_snapshot
      AccountSnapshotUpdateJob.perform_later(trading_account) if closed?
    end
end