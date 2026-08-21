require "test_helper"

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    test "registers a donor and ignores submitted privileged roles" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: {
          user: {
            name: "New Donor",
            email: "new.donor@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "admin"
          }
        }
      end

      user = User.find_by!(email: "new.donor@example.com")
      assert_predicate user, :donor?
      assert_redirected_to profile_path
    end

    test "renders the registration form" do
      get new_user_registration_path

      assert_response :success
      assert_select "h1", text: "Keep your giving history together."
      assert_select "select[name='user[role]']", count: 0
    end
  end
end
