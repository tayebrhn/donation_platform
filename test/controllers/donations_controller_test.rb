require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the donation form for an active project" do
    project = projects(:school_library)

    get new_project_donation_url(project)

    assert_response :success
    assert_select "h1", text: /Put your support behind/
    assert_select "form[action=?][method=?]", new_project_donation_path(project), "get"
    assert_select "input[name='donation[donor_name]'][required]"
    assert_select "input[name='donation[donor_email]'][required]"
    assert_select "input[name='donation[amount]'][min='1'][max='10000']"
    assert_select "button[type='submit'][disabled]", text: /Continue to payment/
  end

  test "does not render a donation form for a draft project" do
    get new_project_donation_url(projects(:community_garden))

    assert_response :not_found
  end
end
