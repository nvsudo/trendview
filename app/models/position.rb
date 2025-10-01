class Position < ApplicationRecord
  acts_as_tenant(:user)

  # Associations
  belongs_to :trading_account
  belongs_to :security
  has_one :user, through: :trading_account

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :average_price, presence: true, numericality: { greater_than: 0 }
  validates :position_type, presence: true

  # Enums
  enum :position_type, {
    long: "long",
    short: "short"
  }, default: :long

  # Scopes
  scope :long_positions, -> { where(position_type: :long) }
  scope :short_positions, -> { where(position_type: :short) }
  scope :profitable, -> { where("unrealized_pnl > 0") }
  scope :losing, -> { where("unrealized_pnl < 0") }

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
    # In production, this would integrate with broker API
    # For now, just mark as closed
    update(quantity: 0, closed_at: Time.current)
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
end
