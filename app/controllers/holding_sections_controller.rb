class HoldingSectionsController < ApplicationController
  before_action :set_holding_section, only: [:show, :edit, :update, :destroy]

  def index
    @sections = current_user.holding_sections.ordered
  end

  def show
  end

  def new
    @section = current_user.holding_sections.build
  end

  def create
    @section = current_user.holding_sections.build(section_params)
    @section.position = next_position
    
    if @section.save
      redirect_to dashboard_path, notice: 'Section created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @section.update(section_params)
      redirect_to dashboard_path, notice: 'Section updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @section.destroy
    redirect_to dashboard_path, notice: 'Section deleted successfully'
  end

  private

  def set_holding_section
    @section = current_user.holding_sections.find(params[:id])
  end

  def section_params
    params.require(:holding_section).permit(:name, :description, :color)
  end

  def next_position
    current_user.holding_sections.maximum(:position).to_i + 1
  end
end
