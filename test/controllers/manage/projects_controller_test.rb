require "test_helper"

module Manage
  class ProjectsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @manager = users(:project_manager)
      @managed_project = projects(:community_garden)
      @managed_project.update!(project_manager: @manager)
    end

    test "requires authentication" do
      get manage_projects_path

      assert_redirected_to new_user_session_path
    end

    test "does not allow donors into project management" do
      sign_in users(:donor)

      get manage_projects_path

      assert_redirected_to root_path
      assert_equal "You are not authorized to access that area.", flash[:alert]
    end

    test "lists only projects assigned to the project manager" do
      sign_in @manager

      get manage_projects_path

      assert_response :success
      assert_select ".data-row", count: 1
      assert_select "body", text: /Create a Community Garden/
      assert_no_match "Build a School Library", response.body
    end

    test "renders the new project form for a project manager" do
      sign_in @manager

      get new_manage_project_path

      assert_response :success
      assert_select "h1", text: "Create a project."
      assert_select "select[name='project[project_manager_id]']", count: 0
    end

    test "prevents a project manager from accessing another project" do
      sign_in @manager

      get manage_project_path(projects(:school_library))

      assert_response :not_found
    end

    test "creates a project owned by the signed-in manager" do
      sign_in @manager

      assert_difference("Project.count", 1) do
        post manage_projects_path, params: {
          project: {
            title: "Fund a Music Room",
            description: "Provide instruments and acoustic improvements.",
            goal_amount_cents: 250_000,
            currency: "USD",
            status: "draft",
            project_manager_id: users(:admin).id
          }
        }
      end

      project = Project.find_by!(title: "Fund a Music Room")
      assert_equal @manager, project.project_manager
      assert_redirected_to manage_project_path(project)
    end

    test "allows an admin to manage any project" do
      sign_in users(:admin)

      get manage_project_path(projects(:school_library))

      assert_response :success
    end

    test "allows an admin to assign a project manager" do
      sign_in users(:admin)

      patch manage_project_path(projects(:school_library)), params: {
        project: { project_manager_id: @manager.id }
      }

      assert_redirected_to manage_project_path(projects(:school_library))
      assert_equal @manager, projects(:school_library).reload.project_manager
    end

    test "renders manager assignment for an admin" do
      sign_in users(:admin)

      get edit_manage_project_path(@managed_project)

      assert_response :success
      assert_select "select[name='project[project_manager_id]']"
    end
  end
end
