class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_onboarding only: [ :update ]

  # Whitelist of allowed onboarding step names for security
  ALLOWED_ONBOARDING_STEPS = %w[trading_profile first_account initial_data].freeze

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      login(@user)
      redirect_to root_path, notice: "Welcome to Ignition! Your account has been created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @user = current_user

    # Handle onboarding step completion
    if params[:step_name].present?
      # Security: Validate step_name against whitelist to prevent path traversal
      unless ALLOWED_ONBOARDING_STEPS.include?(params[:step_name])
        redirect_to_current_onboarding_step
        return
      end

      step_data = params[:step_data]&.to_unsafe_h || {}

      begin
        @user.complete_onboarding_step!(params[:step_name], step_data)

        # Redirect to next step or dashboard
        if @user.onboarded?
          redirect_to root_path, notice: "Welcome aboard! Your trading journal is ready."
        else
          redirect_to_current_onboarding_step
        end
      rescue => e
        # Re-render the current onboarding step if error occurs
        flash.now[:alert] = "Unable to complete step: #{e.message}"
        render "onboardings/#{params[:step_name]}", status: :unprocessable_entity
      end
    else
      # Regular profile update
      if @user.update(user_update_params)
        redirect_to root_path, notice: "Profile updated successfully."
      else
        redirect_to root_path, alert: "Unable to update profile."
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def user_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :avatar, :trading_style,
                                  :risk_tolerance, :primary_goal)
  end
end
