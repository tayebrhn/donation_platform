require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    project = Project.new(
      title: "Fund a Science Lab",
      description: "Provide equipment for hands-on science lessons.",
      goal_amount_cents: 750_000,
      currency: "USD",
      status: "draft"
    )

    assert_predicate project, :valid?
  end

  test "requires a title and description" do
    project = Project.new(goal_amount_cents: 750_000)

    assert_predicate project, :invalid?
    assert_includes project.errors[:title], "can't be blank"
    assert_includes project.errors[:description], "can't be blank"
  end

  test "requires a positive integer goal" do
    project = projects(:school_library)

    project.goal_amount_cents = 0
    assert_predicate project, :invalid?

    project.goal_amount_cents = 10.5
    assert_predicate project, :invalid?
  end

  test "requires a supported status and uppercase currency code" do
    project = projects(:school_library)

    project.status = "paused"
    project.currency = "usd"

    assert_predicate project, :invalid?
    assert_includes project.errors[:status], "is not included in the list"
    assert_includes project.errors[:currency], "is invalid"
  end

  test "has many donations" do
    assert_equal 4, projects(:school_library).donations.size
  end

  test "amount raised includes only succeeded donations" do
    assert_equal 425_000, projects(:school_library).amount_raised
  end

  test "calculates remaining amount" do
    assert_equal 575_000, projects(:school_library).remaining_amount
  end

  test "calculates progress to one decimal place" do
    assert_equal BigDecimal("42.5"), projects(:school_library).progress_percentage
  end

  test "caps progress at one hundred percent and remaining amount at zero" do
    project = projects(:community_garden)
    project.donations.create!(
      donor_name: "Taylor Quinn",
      donor_email: "taylor@example.com",
      amount_cents: 600_000,
      currency: "USD",
      status: "succeeded"
    )

    assert_equal BigDecimal("100.0"), project.progress_percentage
    assert_equal 0, project.remaining_amount
  end
end
