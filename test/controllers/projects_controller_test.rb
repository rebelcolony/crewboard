require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
  end

  test "GET index lists tenant projects" do
    get projects_path
    assert_response :success
    assert_match "Forties Alpha Inspection", response.body
    assert_no_match "Deepwater Horizon Survey", response.body
  end

  test "GET show renders project" do
    get project_path(projects(:forties))
    assert_response :success
  end

  test "GET new renders form" do
    projects(:brent).destroy  # make room under free-tier limit
    get new_project_path
    assert_response :success
    assert_select "form"
  end

  test "POST create adds a project to current account" do
    projects(:brent).destroy  # make room under free-tier limit
    assert_difference "Project.count", 1 do
      post projects_path, params: {
        project: { name: "New Survey", location: "Aberdeen", status: "not_started", progress: 0 }
      }
    end
    project = Project.last
    assert_equal accounts(:aberdeen), project.account
    assert_redirected_to projects_path
  end

  test "POST create with invalid params re-renders form" do
    projects(:brent).destroy  # make room under free-tier limit
    assert_no_difference "Project.count" do
      post projects_path, params: { project: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update modifies project" do
    patch project_path(projects(:forties)), params: { project: { progress: 80 } }
    assert_redirected_to projects_path
    assert_equal 80, projects(:forties).reload.progress
  end

  test "DELETE destroy removes project" do
    assert_difference "Project.count", -1 do
      delete project_path(projects(:forties))
    end
    assert_redirected_to projects_path
  end

  test "cannot access other tenant project" do
    get project_path(projects(:other_project))
    assert_response :not_found
  end
end
