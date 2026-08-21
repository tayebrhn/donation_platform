require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get admin_users_path

      assert_redirected_to new_user_session_path
    end

    test "does not allow a project manager into user administration" do
      sign_in users(:project_manager)

      get admin_users_path

      assert_redirected_to root_path
    end

    test "lists users for an admin" do
      sign_in users(:admin)

      get admin_users_path

      assert_response :success
      assert_select ".data-row", count: 3
    end

    test "renders the role editor for an admin" do
      sign_in users(:admin)

      get edit_admin_user_path(users(:donor))

      assert_response :success
      assert_select "select[name='user[role]'] option", count: 3
    end

    test "allows an admin to change a user's role" do
      sign_in users(:admin)
      donor = users(:donor)

      patch admin_user_path(donor), params: { user: { role: "project_manager", email: "attacker@example.com" } }

      assert_redirected_to admin_users_path
      donor.reload
      assert_predicate donor, :project_manager?
      assert_equal "dana@example.com", donor.email
    end

    test "rejects an unsupported role" do
      sign_in users(:admin)
      donor = users(:donor)

      patch admin_user_path(donor), params: { user: { role: "auditor" } }

      assert_response :unprocessable_content
      assert_predicate donor.reload, :donor?
    end

    test "prevents an admin from demoting their own account" do
      admin = users(:admin)
      sign_in admin

      patch admin_user_path(admin), params: { user: { role: "donor" } }

      assert_response :unprocessable_content
      assert_predicate admin.reload, :admin?
      assert_select ".form-errors", text: /cannot be changed for your own account/
    end
  end
end
