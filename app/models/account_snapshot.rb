class AccountSnapshot < ApplicationRecord
  # Associations
  belongs_to :trading_account
  has_one :user, through: :trading_account

  # Multi-tenancy through trading_account
  delegate :user, to: :trading_account

  # Validations
  validates :date, presence: true, uniqueness: { scope: :trading_account_id }
  validates :total_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :recent, -> { order(date: :desc) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :this_year, -> { where(date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  # Performance calculations
  def daily_return_percentage
    return 0 unless day_pnl.present? && total_value.present? && total_value > 0
    (day_pnl / total_value * 100).round(2)
  end

  def deployment_ratio
    return 0 unless invested_amount.present? && total_value.present? && total_value > 0
    (invested_amount / total_value * 100).round(2)
  end

  # Display methods
  def formatted_total_value
    "₹#{total_value.to_f.round(2)}"
  end

  def formatted_day_pnl
    return "₹0.00" unless day_pnl.present?
    pnl = day_pnl.to_f
    sign = pnl >= 0 ? "+" : ""
    "#{sign}₹#{pnl.round(2)}"
  end

  def pnl_color_class
    return "text-gray-500" unless day_pnl.present?
    day_pnl >= 0 ? "text-green-600" : "text-red-600"
  end

  # Class methods for analytics
  def self.latest_for_account(trading_account)
    where(trading_account: trading_account).recent.first
  end

  def self.portfolio_summary_for_user(user)
    joins(:trading_account)
      .where(trading_accounts: { user: user })
      .group("DATE(date)")
      .order("DATE(date) DESC")
      .sum(:total_value)
  end
end
