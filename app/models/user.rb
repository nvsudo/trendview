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
    attachable.variant :thumbnail, resize_to_fill: [ 300, 300 ], convert: :webp, saver: { quality: 80 }
    attachable.variant :small, resize_to_fill: [ 72, 72 ], convert: :webp, saver: { quality: 80 }, preprocessed: true
  end

  validate :avatar_size

  # Token generation for password reset
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  # User display methods
  def display_name
    [ first_name, last_name ].compact.join(" ").presence || email
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

  # ========================================
  # PERSISTENT ONBOARDING SYSTEM
  # Superhuman-style progressive disclosure
  # ========================================

  # Onboarding step sequence
  ONBOARDING_STEPS = %w[profile trading_profile first_account initial_data completed].freeze

  # Check if user has completed full onboarding
  def onboarded?
    onboarding_completed_at.present? && minimum_scaffolding_complete?
  end

  # Check if user needs to complete onboarding
  def needs_onboarding?
    !onboarded?
  end

  # Check if minimum scaffolding is complete (all gates passed)
  def minimum_scaffolding_complete?
    has_trading_profile && has_trading_account && has_initial_data
  end

  # Get current onboarding step based on completion state
  def current_onboarding_step
    return "completed" if onboarded?
    return "profile" unless profile_complete?
    return "trading_profile" unless has_trading_profile
    return "first_account" unless has_trading_account
    return "initial_data" unless has_initial_data
    "completed"
  end

  # Complete a specific onboarding step and advance
  def complete_onboarding_step!(step_name, data = {})
    transaction do
      # Set started timestamp on first step
      update!(onboarding_started_at: Time.current) if onboarding_started_at.nil?

      # Save partial data for this step
      unless data.empty?
        current_data = onboarding_data || {}
        update!(onboarding_data: current_data.merge(data))
      end

      # Mark step as complete
      case step_name.to_s
      when "profile"
        # Profile completion tracked via profile_complete? method
        update!(onboarding_step: "trading_profile")
      when "trading_profile"
        update!(
          has_trading_profile: true,
          onboarding_step: "first_account"
        )
      when "first_account"
        update!(
          has_trading_account: true,
          onboarding_step: "initial_data"
        )
      when "initial_data"
        update!(
          has_initial_data: true,
          onboarding_step: "completed",
          onboarding_completed_at: Time.current
        )
      end
    end
  end

  # Check if profile step is complete (Step 1)
  def profile_complete?
    first_name.present? && last_name.present? && email.present?
  end

  # Calculate onboarding progress percentage
  def onboarding_progress_percentage
    completed_steps = 0
    total_steps = 4

    completed_steps += 1 if profile_complete?
    completed_steps += 1 if has_trading_profile
    completed_steps += 1 if has_trading_account
    completed_steps += 1 if has_initial_data

    ((completed_steps.to_f / total_steps) * 100).round
  end

  # Get human-readable current step name
  def current_step_name
    case current_onboarding_step
    when "profile"
      "Your Profile"
    when "trading_profile"
      "Trading Profile"
    when "first_account"
      "First Account"
    when "initial_data"
      "Initial Data"
    when "completed"
      "Complete"
    else
      "Unknown"
    end
  end

  # Get step number for progress tracking
  def current_step_number
    ONBOARDING_STEPS.index(current_onboarding_step) + 1
  end

  # Get saved data for a specific step (for pre-filling forms)
  def onboarding_step_data(step_name)
    (onboarding_data || {})[step_name.to_s] || {}
  end

  # Reset onboarding (allow user to start fresh)
  def reset_onboarding!
    update!(
      onboarding_step: "profile",
      onboarding_started_at: nil,
      onboarding_completed_at: nil,
      has_trading_profile: false,
      has_trading_account: false,
      has_initial_data: false,
      onboarding_data: {},
      onboarding_data_path: nil
    )
  end

  # Check if user abandoned onboarding
  def onboarding_abandoned?
    return false if onboarded?
    return false if onboarding_started_at.nil?

    # Consider abandoned if started but no activity for 7 days
    onboarding_started_at < 7.days.ago && !onboarded?
  end

  private

    def avatar_size
      if avatar.attached? && avatar.byte_size > 5.megabytes
        errors.add(:avatar, "must be less than 5MB")
      end
    end
end
