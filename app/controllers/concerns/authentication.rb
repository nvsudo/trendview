module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_request_details
    before_action :authenticate_user!
    before_action :set_sentry_user
    before_action :require_onboarding

    helper_method :current_user, :authenticated?, :user_signed_in?
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
      skip_before_action :set_sentry_user, **options
    end

    def skip_onboarding(**options)
      skip_before_action :require_onboarding, **options
    end
  end

  def current_user
    ::Current.user
  end

  def authenticated?
    ::Current.user.present?
  end

  def user_signed_in?
    authenticated?
  end

  def login(user)
    session = create_session_for(user)
    ::Current.session = session
  end

  def logout
    cookies.delete(:session_token)
    ::Current.session = nil
  end

  private
    def authenticate_user!
      if session_record = find_session_by_cookie
        ::Current.session = session_record
      else
        redirect_to new_session_url
      end
    end

    def find_session_by_cookie
      cookie_value = cookies.signed[:session_token]

      if cookie_value.present?
        Session.find_by(id: cookie_value)
      else
        nil
      end
    end

    def create_session_for(user)
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      session
    end


    def set_request_details
      ::Current.user_agent = request.user_agent
      ::Current.ip_address = request.ip
    end

    def set_sentry_user
      return unless defined?(Sentry) && ENV["SENTRY_DSN"].present?

      if ::Current.user
        Sentry.set_user(
          id: ::Current.user.id,
          email: ::Current.user.email,
          username: ::Current.user.display_name,
          ip_address: ::Current.ip_address
        )
      end
    end

    # Onboarding enforcement - Superhuman style (no app access until complete)
    def require_onboarding
      return unless ::Current.user
      return unless redirectable_path?(request.path)

      if ::Current.user.needs_onboarding?
        redirect_to_current_onboarding_step
      end
    end

    # Check if current path should trigger onboarding redirect
    def redirectable_path?(path)
      # Don't redirect if already on onboarding pages
      return false if path.start_with?("/onboarding")

      # Don't redirect if on session/auth pages
      return false if path.start_with?("/sessions")
      return false if path.start_with?("/registration")
      return false if path.start_with?("/password")

      # Don't redirect health checks or assets
      return false if path.start_with?("/up")
      return false if path.start_with?("/assets")
      return false if path.start_with?("/rails")

      true
    end

    # Smart auto-resume: redirect to user's current incomplete step
    def redirect_to_current_onboarding_step
      step = ::Current.user.current_onboarding_step

      case step
      when "profile"
        redirect_to onboarding_path
      when "trading_profile"
        redirect_to trading_profile_onboarding_path
      when "first_account"
        redirect_to first_account_onboarding_path
      when "initial_data"
        redirect_to initial_data_onboarding_path
      when "completed"
        # Shouldn't happen, but handle gracefully
        nil
      end
    end
end
