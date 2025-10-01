class OnboardingsController < ApplicationController
  skip_onboarding only: [ :show, :trading_profile, :first_account, :initial_data, :reset ]

  # Step 1: Basic profile (existing registration flow)
  def show
    @user = current_user
    @progress = @user.onboarding_progress_percentage
  end

  # Step 2: Trading profile
  def trading_profile
    # Ensure user is on the correct step
    unless current_user.current_onboarding_step == "trading_profile"
      redirect_to_current_onboarding_step
      return
    end

    @user = current_user
    @progress = @user.onboarding_progress_percentage

    # Pre-fill with saved data if available
    saved_data = @user.onboarding_step_data("trading_profile")
    @trading_style = saved_data["trading_style"]
    @risk_tolerance = saved_data["risk_tolerance"]
    @primary_goal = saved_data["primary_goal"]
  end

  # Step 3: First trading account
  def first_account
    # Ensure user is on the correct step
    unless current_user.current_onboarding_step == "first_account"
      redirect_to_current_onboarding_step
      return
    end

    @user = current_user
    @progress = @user.onboarding_progress_percentage

    # Pre-fill with saved data if available
    saved_data = @user.onboarding_step_data("first_account")
    @account_name = saved_data["account_name"]
    @account_type = saved_data["account_type"]
    @broker = saved_data["broker"]
    @account_size = saved_data["account_size"]
    @currency = saved_data["currency"]
  end

  # Step 4: Initial data (choose path)
  def initial_data
    # Ensure user is on the correct step
    unless current_user.current_onboarding_step == "initial_data"
      redirect_to_current_onboarding_step
      return
    end

    @user = current_user
    @progress = @user.onboarding_progress_percentage
  end

  # Allow user to restart onboarding
  def reset
    current_user.reset_onboarding!
    redirect_to onboarding_path, notice: "Onboarding has been reset. Let's start fresh!"
  end
end
