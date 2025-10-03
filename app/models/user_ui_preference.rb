class UserUiPreference < ApplicationRecord
  belongs_to :user

  validates :preference_category, presence: true
  validates :preference_key, presence: true
  validates :preference_value, presence: true
  validates :preference_key, uniqueness: { scope: [:user_id, :preference_category] }

  # Scopes for common queries
  scope :for_category, ->(category) { where(preference_category: category) }
  scope :for_key, ->(key) { where(preference_key: key) }

  # Class methods for easy access
  def self.get(user, category, key, default = {})
    pref = user.ui_preferences
               .for_category(category)
               .for_key(key)
               .first

    pref&.preference_value || default
  end

  def self.set(user, category, key, value, description = nil)
    pref = user.ui_preferences
               .find_or_initialize_by(
                 preference_category: category,
                 preference_key: key
               )

    pref.preference_value = value
    pref.description = description if description
    pref.save!
    pref
  end

  def self.update_nested(user, category, key, path, value)
    pref = get_record(user, category, key)
    current_value = pref&.preference_value || {}

    # Update nested JSONB value (e.g., columns.symbol.visible = true)
    keys = path.split('.')
    nested = current_value
    keys[0..-2].each { |k| nested = nested[k] ||= {} }
    nested[keys.last] = value

    set(user, category, key, current_value)
  end

  private

  def self.get_record(user, category, key)
    user.ui_preferences
        .for_category(category)
        .for_key(key)
        .first
  end
end
