class Current < ActiveSupport::CurrentAttributes
  attribute :user_agent, :ip_address

  attribute :session

  def user
    session&.user
  end
end