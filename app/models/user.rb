class User < ApplicationRecord
  has_secure_password

  # Trading-specific associations
  has_many :trading_accounts, dependent: :destroy
  has_many :trades, dependent: :destroy
  has_many :user_stock_analyses, dependent: :destroy
  has_many :account_snapshots, through: :trading_accounts

  # Authentication and sessions
  has_many :sessions, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.blank? }
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, with: ->(value) { value.strip.presence }

  # User roles for potential admin features
  enum :role, { trader: "trader", admin: "admin" }, default: :trader, validate: true

  # Profile image handling
  has_one_attached :avatar do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [300, 300], convert: :webp, saver: { quality: 80 }
    attachable.variant :small, resize_to_fill: [72, 72], convert: :webp, saver: { quality: 80 }, preprocessed: true
  end

  validate :avatar_size

  # Token generation for password reset
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  # User display methods
  def display_name
    [first_name, last_name].compact.join(" ").presence || email
  end

  def initials
    if first_name.present? && last_name.present?
      "#{first_name.first}#{last_name.first}".upcase
    else
      email.first.upcase
    end
  end

  # Trading-specific methods
  def primary_trading_account
    trading_accounts.where(is_primary: true).first || trading_accounts.first
  end

  def total_portfolio_value
    trading_accounts.sum(&:current_portfolio_value)
  end

  def total_deployed_percentage
    return 0 if total_portfolio_value.zero?

    total_accounts = trading_accounts.count
    return 0 if total_accounts.zero?

    average_deployment = trading_accounts.sum(&:deployed_percentage) / total_accounts
    average_deployment.round(2)
  end

  # AI features
  def ai_insights_enabled?
    ai_insights_enabled && ENV["OPENAI_ACCESS_TOKEN"].present?
  end

  private

    def avatar_size
      if avatar.attached? && avatar.byte_size > 5.megabytes
        errors.add(:avatar, "must be less than 5MB")
      end
    end
end