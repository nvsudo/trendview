class TradesController < ApplicationController
  before_action :set_trade, only: [ :show, :edit, :update, :destroy ]

  def index
    @trades = current_user.trades.includes(:security, :trading_account)
                          .order(entry_date: :desc)
                          .page(params[:page])
  end

  def show
  end

  def new
    @trade = current_user.trades.build
  end

  def create
    @trade = current_user.trades.build(trade_params)

    if @trade.save
      redirect_to @trade, notice: "Trade was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @trade.update(trade_params)
      redirect_to @trade, notice: "Trade was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_url, notice: "Trade was successfully deleted."
  end

  private

  def set_trade
    @trade = current_user.trades.find(params[:id])
  end

  def trade_params
    params.require(:trade).permit(:trading_account_id, :security_id, :trade_type,
                                  :quantity, :entry_price, :exit_price, :entry_date,
                                  :exit_date, :strategy, :timeframe, :status,
                                  :planned_stop_loss, :planned_target, :setup_quality)
  end
end
