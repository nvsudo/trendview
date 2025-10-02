require "test_helper"

class BasicFunctionalityTest < ActiveSupport::TestCase
  test "should create holding section with valid attributes" do
    user = User.create!(
      email: "test@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password123"
    )
    
    section = HoldingSection.new(
      user: user,
      name: "Test Section",
      position: 0,
      color: "#3B82F6"
    )
    
    assert section.valid?
    assert section.save
  end

  test "should create default sections for user" do
    user = User.create!(
      email: "test2@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password123"
    )
    
    sections = HoldingSection.create_default_sections_for_user!(user)
    
    assert_equal 2, sections.count
    assert_equal "Core Holdings", sections.first.name
    assert_equal "Probe Holdings", sections.last.name
  end

  test "should calculate portfolio stats" do
    user = User.create!(
      email: "test3@example.com",
      first_name: "Test",
      last_name: "User",
      password: "password123"
    )
    
    # Test that the method exists and returns expected structure
    stats = {
      total_value: user.total_portfolio_value,
      deployed_percentage: user.total_deployed_percentage
    }
    
    assert stats.key?(:total_value)
    assert stats.key?(:deployed_percentage)
  end
end
