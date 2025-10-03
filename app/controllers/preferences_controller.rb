class PreferencesController < ApplicationController
  before_action :authenticate_user!

  # GET /preferences/:category/:key
  def show
    category = params[:category]
    key = params[:key]
    default = preference_defaults(category, key)

    preference = current_user.get_preference(category, key, default)

    render json: {
      category: category,
      key: key,
      value: preference
    }
  end

  # PUT /preferences/:category/:key
  def update
    category = params[:category]
    key = params[:key]
    value = params[:value]

    current_user.set_preference(category, key, value)

    render json: {
      success: true,
      category: category,
      key: key,
      value: value
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH /preferences/:category/:key/nested
  # For updating single nested value without replacing entire JSONB
  def update_nested
    category = params[:category]
    key = params[:key]
    path = params[:path]  # e.g., "columns.symbol.visible"
    value = params[:value]

    UserUiPreference.update_nested(current_user, category, key, path, value)

    render json: { success: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def preference_defaults(category, key)
    case [category, key]
    when ['positions_table', 'columns']
      DEFAULT_POSITION_COLUMNS
    when ['dashboard', 'layout']
      DEFAULT_DASHBOARD_LAYOUT
    when ['display', 'formats']
      DEFAULT_DISPLAY_FORMATS
    else
      {}
    end
  end
end
