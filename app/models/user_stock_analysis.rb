class UserStockAnalysis < ApplicationRecord
  acts_as_tenant(:user)

  # Associations
  belongs_to :user
  belongs_to :security

  # Validations
  validates :user_id, uniqueness: { scope: :security_id }
  validates :user_stage, inclusion: { in: [1, 2, 3, 4] }, allow_nil: true
  validates :user_rs_rank, numericality: { in: 1.0..10.0 }, allow_nil: true
  validates :setup_quality_rating, inclusion: { in: 1..5 }, allow_nil: true

  # Enums
  enum :conviction_level, {
    low: "low",
    medium: "medium",
    high: "high",
    very_high: "very_high"
  }, default: :medium

  # Scopes
  scope :by_stage, ->(stage) { where(user_stage: stage) }
  scope :by_conviction, ->(level) { where(conviction_level: level) }
  scope :high_quality, -> { where('setup_quality_rating >= ?', 4) }
  scope :recent, -> { order(last_updated_by_user: :desc) }

  # Analysis methods
  def stage_name
    case user_stage
    when 1 then "Stage 1 - Neglect"
    when 2 then "Stage 2 - Accumulation"
    when 3 then "Stage 3 - Markup"
    when 4 then "Stage 4 - Distribution"
    else "Unanalyzed"
    end
  end

  def rs_strength
    return "Unranked" unless user_rs_rank.present?

    case user_rs_rank
    when 8.0..10.0 then "Very Strong"
    when 6.0..7.9 then "Strong"
    when 4.0..5.9 then "Average"
    when 2.0..3.9 then "Weak"
    when 1.0..1.9 then "Very Weak"
    else "Unknown"
    end
  end

  def quality_stars
    setup_quality_rating || 0
  end

  def bullish_setup?
    user_stage.in?([2, 3]) && (user_rs_rank || 0) >= 6.0
  end

  def bearish_setup?
    user_stage.in?([1, 4]) && (user_rs_rank || 0) <= 4.0
  end

  # Price target calculations
  def risk_amount
    return 0 unless target_entry_price.present? && stop_loss_price.present?
    (target_entry_price - stop_loss_price).abs
  end

  def reward_amount
    return 0 unless target_entry_price.present? && target_exit_price.present?
    (target_exit_price - target_entry_price).abs
  end

  def risk_reward_ratio
    return 0 if risk_amount.zero?
    (reward_amount / risk_amount).round(2)
  end

  # Update tracking
  def mark_as_updated!
    update(last_updated_by_user: Time.current, analysis_version: analysis_version + 1)
  end
end