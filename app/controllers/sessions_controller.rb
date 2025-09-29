class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      login(user)
      redirect_to root_path, notice: 'Signed in successfully'
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    logout
    redirect_to new_session_path, notice: 'Signed out successfully'
  end
end