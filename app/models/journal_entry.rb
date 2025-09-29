class JournalEntry < ApplicationRecord
  acts_as_tenant(:user)

  # Associations
  belongs_to :trade
  has_one :user, through: :trade

  # Validations
  validates :entry_type, presence: true
  validates :content, presence: true

  # Enums
  enum :entry_type, {
    pre_trade: "pre_trade",        # Analysis before entering
    during_trade: "during_trade",   # Updates while position is open
    post_trade: "post_trade",      # Review after closing
    lesson_learned: "lesson_learned" # Key takeaways
  }

  enum :mood, {
    confident: "confident",
    nervous: "nervous",
    excited: "excited",
    fearful: "fearful",
    neutral: "neutral",
    frustrated: "frustrated",
    satisfied: "satisfied"
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(entry_type: type) }
  scope :lessons, -> { where(entry_type: :lesson_learned) }

  # Content analysis
  def word_count
    content.split.size
  end

  def has_tags?
    tags.present? && tags.any?
  end

  def tag_list
    tags&.join(", ") || ""
  end

  def set_tags(tag_string)
    self.tags = tag_string.split(",").map(&:strip).reject(&:blank?)
  end

  # Display methods
  def entry_type_display
    entry_type.humanize
  end

  def mood_display
    mood&.humanize || "Not specified"
  end

  def mood_emoji
    case mood
    when "confident" then "😎"
    when "nervous" then "😰"
    when "excited" then "🚀"
    when "fearful" then "😨"
    when "neutral" then "😐"
    when "frustrated" then "😤"
    when "satisfied" then "😊"
    else "📝"
    end
  end

  def short_content(limit = 100)
    return content if content.length <= limit
    "#{content.first(limit)}..."
  end

  # Journal insights
  def self.mood_summary_for_user(user)
    joins(:trade)
      .where(trades: { user: user })
      .group(:mood)
      .count
  end

  def self.lessons_learned_for_user(user)
    joins(:trade)
      .where(trades: { user: user })
      .lessons
      .recent
  end

  def self.entry_frequency_for_user(user)
    joins(:trade)
      .where(trades: { user: user })
      .group_by_day(:created_at, last: 30)
      .count
  end

  # AI integration helpers
  def sentiment_keywords
    # Simple keyword extraction - could be enhanced with AI
    positive_words = %w[good great excellent profit win success breakthrough]
    negative_words = %w[loss mistake error bad terrible wrong failed]

    words = content.downcase.split(/\W+/)

    {
      positive: words.count { |word| positive_words.include?(word) },
      negative: words.count { |word| negative_words.include?(word) }
    }
  end

  def sentiment_score
    keywords = sentiment_keywords
    total = keywords[:positive] + keywords[:negative]
    return 0 if total.zero?

    ((keywords[:positive] - keywords[:negative]).to_f / total * 100).round(1)
  end
end