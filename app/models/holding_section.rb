class HoldingSection < ApplicationRecord
  acts_as_tenant(:user)
  
  belongs_to :user
  has_many :positions, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :position, presence: true
  validates :color, presence: true
  
  scope :ordered, -> { order(:position) }
  scope :default_sections, -> { where(is_default: true) }
  scope :user_sections, -> { where(is_default: false) }
  
  def self.create_default_sections_for_user!(user)
    create!([
      { user: user, name: "Core Holdings", position: 0, is_default: true, color: '#3B82F6' },
      { user: user, name: "Probe Holdings", position: 1, is_default: true, color: '#10B981' }
    ])
  end
end
