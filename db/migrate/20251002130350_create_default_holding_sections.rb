class CreateDefaultHoldingSections < ActiveRecord::Migration[8.0]
  def up
    User.find_each do |user|
      # Create default sections only if user doesn't have any sections yet
      if user.holding_sections.empty?
        HoldingSection.create_default_sections_for_user!(user)
      end
    end
  end

  def down
    # Remove default sections (those marked as is_default: true)
    HoldingSection.where(is_default: true).destroy_all
  end
end
