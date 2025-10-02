class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  def new
  end

  def create
    # Wrap in rescue to catch model loading errors gracefully
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user
      login(user)
      redirect_to root_path, notice: "Signed in successfully"
    else
      # Security best practice: Don't reveal if email exists or not
      # Generic message prevents account enumeration attacks
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  rescue => e
    # Log the error for debugging but show user-friendly message
    Rails.logger.error "Login error: #{e.message}"
    flash.now[:alert] = "Something went wrong. Please try again."
    render :new, status: :unprocessable_entity
  end

  def destroy
    logout
    redirect_to new_session_path, notice: "Signed out successfully"
  end
end
