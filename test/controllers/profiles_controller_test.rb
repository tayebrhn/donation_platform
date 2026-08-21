require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get profile_path

    assert_redirected_to new_user_session_path
  end

  test "shows only the signed-in user's donations" do
    donor = users(:donor)
    donations(:library_first).update!(user: donor)
    sign_in donor

    get profile_path

    assert_response :success
    assert_select "h1", text: donor.name
    assert_select ".data-row", count: 1
    assert_select "body", text: /\$2,500/
    assert_no_match donations(:library_second).donor_name, response.body
  end

  test "updates profile details without permitting a role change" do
    donor = users(:donor)
    sign_in donor

    patch profile_path, params: { user: { name: "Updated Donor", email: "updated@example.com", role: "admin" } }

    assert_redirected_to profile_path
    donor.reload
    assert_equal "Updated Donor", donor.name
    assert_equal "updated@example.com", donor.email
    assert_predicate donor, :donor?
  end
end
