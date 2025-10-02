class DashboardController < ApplicationController
  def index
    @trading_accounts = current_user.trading_accounts.includes(:account_snapshots)
    @recent_trades = current_user.trades.recent.includes(:security).limit(10)
    @portfolio_stats = calculate_enhanced_portfolio_stats
    @holdings_by_section = group_holdings_by_section
    @performance_metrics = calculate_performance_metrics
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
                .map { |month, trades| [ month, trades.sum(&:net_pnl) ] }
                .compact
  end

  def calculate_strategy_breakdown
    current_user.trades.closed
                .group(:strategy)
                .group("CASE WHEN net_pnl > 0 THEN 'profit' ELSE 'loss' END")
                .count
  end

  def calculate_win_rate_trend
    current_user.trades.closed
                .group_by { |trade| trade.exit_date&.beginning_of_month }
                .map do |month, trades|
      winning = trades.select(&:profitable?).count
      total = trades.count
      [ month, total > 0 ? (winning.to_f / total * 100).round(1) : 0 ]
    end.compact
  end

  def calculate_portfolio_allocation
    return {} unless current_user.trades.open.any?

    current_user.trades.open
                .includes(:security)
                .group_by { |trade| trade.security&.sector || "Unknown" }
                .map { |sector, trades| [ sector, trades.sum(&:position_value) ] }
                .to_h
  end

  def calculate_enhanced_portfolio_stats
    total_value = current_user.total_portfolio_value
    deployed_percentage = current_user.total_deployed_percentage
    cash_percentage = 100 - deployed_percentage
    daily_pnl = calculate_daily_pnl
    net_pnl = calculate_net_pnl

    {
      total_value: total_value,
      cash_percentage: cash_percentage,
      daily_pnl: daily_pnl,
      net_pnl: net_pnl,
      deployed_percentage: deployed_percentage
    }
  end

  def group_holdings_by_section
    current_user.holding_sections.ordered.includes(positions: :security)
  end

  def calculate_daily_pnl
    current_user.trades
                .where(entry_date: Date.current.beginning_of_day..Date.current.end_of_day)
                .sum(:net_pnl)
  end

  def calculate_net_pnl
    # Defensive: handle case where user has no positions yet
    return 0 unless current_user.respond_to?(:positions)

    positions = current_user.positions.where("quantity > 0")
    return 0 unless positions.any?

    positions.sum { |pos| pos.unrealized_pnl || 0 }
  rescue NoMethodError => e
    Rails.logger.error "Position calculation error: #{e.message}"
    0
  end

  def calculate_performance_metrics
    {
      current_drawdown: 0.0, # Placeholder
      max_drawdown: 0.0,     # Placeholder
      best_day: 0.0,         # Placeholder
      worst_day: 0.0         # Placeholder
    }
  end
end
