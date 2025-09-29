class ApplicationController < ActionController::Base
  include Authentication

  # Multi-tenancy setup
  set_current_tenant_through_filter
  before_action :set_current_tenant

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def set_current_tenant
    if user_signed_in?
      ActsAsTenant.current_tenant = current_user
    else
      ActsAsTenant.current_tenant = nil
    end
  end
end
