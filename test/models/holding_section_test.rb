require "test_helper"

class HoldingSectionTest < ActiveSupport::TestCase
  setup do
    @user = users(:trader_one)
    @section = HoldingSection.new(
      user: @user,
      name: "Test Section",
      position: 0,
      color: "#3B82F6"
    )
  end

  test "should be valid with valid attributes" do
    assert @section.valid?
  end

  test "should require user" do
    @section.user = nil
    assert_not @section.valid?
    assert_includes @section.errors[:user], "must exist"
  end

  test "should require name" do
    @section.name = nil
    assert_not @section.valid?
    assert_includes @section.errors[:name], "can't be blank"
  end

  test "should require unique name per user" do
    @section.save!
    duplicate_section = HoldingSection.new(
      user: @user,
      name: "Test Section",
      position: 1
    )
    assert_not duplicate_section.valid?
    assert_includes duplicate_section.errors[:name], "has already been taken"
  end

  test "should allow same name for different users" do
    @section.save!
    other_user = users(:trader_two)
    other_section = HoldingSection.new(
      user: other_user,
      name: "Test Section",
      position: 0
    )
    assert other_section.valid?
  end

  test "should create default sections for user" do
    new_user = users(:new_trader)
    sections = HoldingSection.create_default_sections_for_user!(new_user)

    assert_equal 2, sections.count
    assert_equal "Core Holdings", sections.first.name
    assert_equal "Probe Holdings", sections.last.name
    assert sections.first.is_default?
    assert sections.last.is_default?
  end

  test "should scope sections by user" do
    @section.save!
    other_user = users(:trader_two)
    other_section = HoldingSection.create!(
      user: other_user,
      name: "Other Section",
      position: 0
    )

    user_sections = HoldingSection.where(user: @user)
    assert_includes user_sections, @section
    assert_not_includes user_sections, other_section
  end

  test "should have many positions" do
    @section.save!
    position = Position.create!(
      user: @user,
      trading_account: trading_accounts(:main),
      security: securities(:aapl),
      quantity: 100,
      average_price: 150.0,
      holding_section: @section
    )

    assert_includes @section.positions, position
  end

  test "should destroy associated positions when destroyed" do
    @section.save!
    position = Position.create!(
      user: @user,
      trading_account: trading_accounts(:main),
      security: securities(:aapl),
      quantity: 100,
      average_price: 150.0,
      holding_section: @section
    )

    @section.destroy
    position.reload
    assert_nil position.holding_section
  end
end
