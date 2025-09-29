class DashboardController < ApplicationController
  def index
    @trading_accounts = current_user.trading_accounts.includes(:account_snapshots)
    @recent_trades = current_user.trades.recent.includes(:security).limit(10)
    @portfolio_stats = calculate_portfolio_stats
  end

  def analytics
    @portfolio_stats = calculate_portfolio_stats
    @monthly_pnl = calculate_monthly_pnl
    @strategy_breakdown = calculate_strategy_breakdown
    @win_rate_trend = calculate_win_rate_trend
  end

  def portfolio
    @trading_accounts = current_user.trading_accounts.includes(:account_snapshots)
    @open_positions = current_user.trades.open.includes(:security)
    @portfolio_allocation = calculate_portfolio_allocation
    @total_unrealized_pnl = @open_positions.sum(&:unrealized_pnl)
  end

  private

  def calculate_portfolio_stats
    {
      total_value: current_user.total_portfolio_value,
      deployed_percentage: current_user.total_deployed_percentage,
      total_trades: current_user.trades.count,
      winning_trades: current_user.trades.profitable.count,
      losing_trades: current_user.trades.losing.count
    }
  end

  def calculate_monthly_pnl
    current_user.trades.closed
                .group_by { |trade| trade.exit_date&.beginning_of_month }
                .map { |month, trades| [month, trades.sum(&:net_pnl)] }
                .compact
  end

  def calculate_strategy_breakdown
    current_user.trades.closed
                .group(:strategy)
                .group('CASE WHEN net_pnl > 0 THEN \'profit\' ELSE \'loss\' END')
                .count
  end

  def calculate_win_rate_trend
    current_user.trades.closed
                .group_by { |trade| trade.exit_date&.beginning_of_month }
                .map do |month, trades|
      winning = trades.select(&:profitable?).count
      total = trades.count
      [month, total > 0 ? (winning.to_f / total * 100).round(1) : 0]
    end.compact
  end

  def calculate_portfolio_allocation
    return {} unless current_user.trades.open.any?

    current_user.trades.open
                .includes(:security)
                .group_by { |trade| trade.security&.sector || 'Unknown' }
                .map { |sector, trades| [sector, trades.sum(&:position_value)] }
                .to_h
  end
end