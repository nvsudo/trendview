class Position < ApplicationRecord
  acts_as_tenant(:user)

  # Associations
  belongs_to :user
  belongs_to :trading_account
  belongs_to :security
  belongs_to :holding_section, optional: true

  # Validations
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :average_price, presence: true, numericality: { greater_than: 0 }
  validates :position_type, presence: true
  validates :generation, presence: true, numericality: { greater_than: 0 }
  validates :opened_at, presence: true

  # Enums
  enum :status, {
    open: "open",
    closed: "closed"
  }, validate: true

  enum :position_type, {
    long: "long",
    short: "short"
  }, default: :long

  # Scopes
  scope :active, -> { where(status: :open).where("quantity > 0") }
  scope :historical, -> { where(status: :closed) }
  scope :long_positions, -> { where(position_type: :long) }
  scope :short_positions, -> { where(position_type: :short) }
  scope :profitable, -> { where("unrealized_pnl > 0") }
  scope :losing, -> { where("unrealized_pnl < 0") }
  scope :by_section, ->(section) { where(holding_section: section) }
  scope :uncategorized, -> { where(holding_section: nil) }
  scope :for_security, ->(security_id) { where(security_id: security_id) }

  # Lifecycle management
  before_create :set_opened_at
  before_create :set_generation
  after_update :check_position_closure

  # Position calculations
  def current_value
    return 0 unless security.last_price.present?
    quantity * security.last_price
  end

  def invested_amount
    quantity * average_price
  end

  def unrealized_pnl
    return 0 unless security.last_price.present?

    case position_type
    when "long"
      (security.last_price - average_price) * quantity
    when "short"
      (average_price - security.last_price) * quantity
    end
  end

  def unrealized_pnl_percent
    return 0 if invested_amount.zero?
    (unrealized_pnl / invested_amount * 100).round(2)
  end

  def portfolio_weight_percent(total_portfolio_value)
    return 0 if total_portfolio_value.zero?
    (current_value / total_portfolio_value * 100).round(1)
  end

  def profitable?
    unrealized_pnl > 0
  end

  def losing?
    unrealized_pnl < 0
  end

  def breakeven?
    unrealized_pnl.abs < 10 # Within ₹10 of breakeven
  end

  # Display methods
  def formatted_value
    "₹#{current_value.round(2)}"
  end

  def formatted_pnl
    pnl = unrealized_pnl
    sign = pnl >= 0 ? "+" : ""
    "#{sign}₹#{pnl.round(2)}"
  end

  def pnl_color_class
    return "text-gray-500" if breakeven?
    profitable? ? "text-green-600" : "text-red-600"
  end

  # Position management
  def close_position!
    update!(
      status: :closed,
      closed_at: Time.current
    )
  end

  def adjust_quantity!(new_quantity)
    return false if new_quantity < 0

    if new_quantity.zero?
      close_position!
    else
      update(quantity: new_quantity)
    end
  end

  def update_market_price!
    # This would be called by background job to update current prices
    return unless security.last_price.present?

    calculated_pnl = unrealized_pnl
    update(
      unrealized_pnl: calculated_pnl,
      last_updated: Time.current
    )
  end

  # Class methods for finding/creating positions
  def self.find_or_create_for_trade(trade)
    # Check if there's an existing OPEN position
    existing = where(
      user: trade.user,
      trading_account: trade.trading_account,
      security: trade.security,
      status: :open
    ).first

    return existing if existing

    # No open position - create new one with next generation number
    create_new_position(trade)
  end

  def self.create_new_position(trade)
    next_gen = calculate_next_generation(
      trade.user,
      trade.trading_account,
      trade.security
    )

    create!(
      user: trade.user,
      trading_account: trade.trading_account,
      security: trade.security,
      generation: next_gen,
      status: :open,
      quantity: 0,
      average_price: trade.entry_price,
      position_type: trade.trade_type == "buy" ? :long : :short,
      opened_at: trade.entry_date || Time.current
    )
  end

  def self.calculate_next_generation(user, trading_account, security)
    max_gen = where(
      user: user,
      trading_account: trading_account,
      security: security
    ).maximum(:generation) || 0

    max_gen + 1
  end

  private

  def set_opened_at
    self.opened_at ||= Time.current
  end

  def set_generation
    if generation.nil?
      self.generation = self.class.calculate_next_generation(
        user,
        trading_account,
        security
      )
    end
  end

  def check_position_closure
    if quantity_changed? && quantity <= 0 && status == "open"
      close_position!
    end
  end
end
