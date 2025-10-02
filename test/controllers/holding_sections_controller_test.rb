require "test_helper"

class HoldingSectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get holding_sections_index_url
    assert_response :success
  end

  test "should get create" do
    get holding_sections_create_url
    assert_response :success
  end

  test "should get update" do
    get holding_sections_update_url
    assert_response :success
  end

  test "should get destroy" do
    get holding_sections_destroy_url
    assert_response :success
  end
end
