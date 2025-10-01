require "test_helper"

class BootTest < ActionDispatch::IntegrationTest
  test "application boots in production mode without errors" do
    # This test ensures all classes can be loaded (simulating production eager_load)
    # It catches missing gem dependencies before deployment

    # Force eager load all application code
    Rails.application.eager_load!

    # Verify core components are loadable
    assert ApplicationComponent
    assert DesignSystemComponent

    # Verify the app responds to basic requests
    get root_url
    assert_response :success
  end

  test "database migrations are up to date" do
    # Catches missing migrations before deployment
    assert ActiveRecord::Migration.check_all_pending!.nil?
  end
end
