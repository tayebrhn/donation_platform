require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "root lists active projects" do
    get root_url

    assert_response :success
    assert_select "h1", text: "Good work deserves a crowd."
    assert_select ".project-card", count: 1
    assert_select "h3", text: "Build a School Library"
    assert_no_match "Create a Community Garden", response.body
  end

  test "shows an active project with fundraising progress" do
    project = projects(:school_library)

    get project_url(project)

    assert_response :success
    assert_select "h1", text: project.title
    assert_select "progress.progress-bar[value='42.5'][max='100']"
    assert_select "body", text: /\$4,250/
    assert_select "body", text: /\$5,750 to go/
    assert_select "a[href=?]", new_project_donation_path(project), text: /Donate to this project/
  end

  test "does not expose draft projects publicly" do
    get project_url(projects(:community_garden))

    assert_response :not_found
  end

  test "returns not found for a missing project" do
    get project_url(id: 0)

    assert_response :not_found
  end
end
