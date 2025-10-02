class PositionsController < ApplicationController
  def move_to_section
    @position = current_user.positions.find(params[:id])
    section_id = params[:section_id]

    if section_id.present?
      @position.holding_section = current_user.holding_sections.find(section_id)
    else
      @position.holding_section = nil
    end

    if @position.save
      render json: { success: true }
    else
      render json: { errors: @position.errors }, status: :unprocessable_entity
    end
  end
end
