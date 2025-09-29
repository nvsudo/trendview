class TradingAccountsController < ApplicationController
  before_action :set_trading_account, only: [:show, :edit, :update]

  def index
    @trading_accounts = current_user.trading_accounts.includes(:user)
  end

  def show
    @account_snapshot = @trading_account.account_snapshots.recent.first
    @recent_trades = @trading_account.trades.recent.limit(10)
  end

  def new
    @trading_account = current_user.trading_accounts.build
  end

  def create
    @trading_account = current_user.trading_accounts.build(trading_account_params)

    if @trading_account.save
      redirect_to @trading_account, notice: 'Trading account was successfully connected.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @trading_account.update(trading_account_params)
      redirect_to @trading_account, notice: 'Trading account was successfully updated.'
    else
      render :edit
    end
  end

  private

  def set_trading_account
    @trading_account = current_user.trading_accounts.find(params[:id])
  end

  def trading_account_params
    params.require(:trading_account).permit(:zerodha_user_id, :account_name,
                                           :account_type, :is_primary, :broker_name,
                                           :account_number)
  end
end