module DashboardHelper
  # Safely calculate percentage change, handling division by zero
  def safe_percentage(numerator, denominator)
    return "0.00" if denominator.nil? || denominator.zero?
    ((numerator.to_f / denominator.to_f) * 100).round(2)
  end

  # Format percentage change with color and sign
  def format_percentage_change(value, total)
    percentage = safe_percentage(value, total)
    sign = value >= 0 ? "+" : ""
    "#{sign}#{percentage}%"
  end
end
