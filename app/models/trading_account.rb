class TradingAccount < ApplicationRecord
  acts_as_tenant(:user)

  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :account_snapshots, dependent: :destroy

  # Encrypted credentials for Zerodha API
  encrypts :api_credentials

  # Validations
  validates :account_name, presence: true
  validates :zerodha_user_id, presence: true, uniqueness: true
  validates :account_type, presence: true

  # Account types for different trading strategies
  enum :account_type, {
    personal: "personal",
    aggressive: "aggressive",
    conservative: "conservative",
    family: "family",
    retirement: "retirement"
  }, default: :personal

  # Account status
  enum :status, {
    active: "active",
    inactive: "inactive",
    syncing: "syncing",
    error: "error"
  }, default: :active

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :connected, -> { where(status: :active) }

  # Callbacks
  before_create :set_primary_if_first
  after_update :ensure_single_primary, if: :saved_change_to_is_primary?

  # Portfolio methods
  def current_portfolio_value
    account_snapshots.recent.first&.total_value || 0
  end

  def deployed_percentage
    snapshot = account_snapshots.recent.first
    return 0 unless snapshot&.total_value&.positive?

    ((snapshot.invested_amount || 0) / snapshot.total_value * 100).round(2)
  end

  def daily_pnl
    account_snapshots.recent.first&.day_pnl || 0
  end

  def monthly_performance
    snapshots = account_snapshots
      .where(date: 1.month.ago.beginning_of_month..Date.current)
      .order(:date)

    return 0 if snapshots.empty?

    start_value = snapshots.first.total_value
    end_value = snapshots.last.total_value

    return 0 if start_value.zero?

    ((end_value - start_value) / start_value * 100).round(2)
  end

  # API integration
  def api_connected?
    api_credentials.present? && zerodha_user_id.present?
  end

  def sync_portfolio!
    return unless api_connected?

    ZerodhaPortfolioSyncJob.perform_later(self)
    update(status: :syncing)
  end

  def store_api_credentials(access_token, refresh_token = nil)
    credentials = {
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: 24.hours.from_now
    }

    update(api_credentials: credentials)
  end

  def valid_api_credentials?
    return false unless api_credentials

    expires_at = api_credentials["expires_at"]
    expires_at.present? && Time.parse(expires_at) > Time.current
  end

  private

    def set_primary_if_first
      self.is_primary = true if user.trading_accounts.empty?
    end

    def ensure_single_primary
      if is_primary?
        user.trading_accounts.where.not(id: id).update_all(is_primary: false)
      end
    end
end