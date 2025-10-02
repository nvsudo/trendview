require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  test "should get move_to_section" do
    get positions_move_to_section_url
    assert_response :success
  end
end
