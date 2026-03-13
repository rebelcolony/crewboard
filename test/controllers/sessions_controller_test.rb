require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders login page" do
    get new_session_path
    assert_response :success
    assert_select "input[name=email_address]"
  end

  test "POST create with valid credentials signs in and redirects" do
    post session_path, params: { email_address: "admin@crewboard.com", password: "password123" }
    assert_redirected_to root_path
    assert cookies[:session_token].present?
  end

  test "POST create with invalid credentials redirects back" do
    post session_path, params: { email_address: "admin@crewboard.com", password: "wrong" }
    assert_redirected_to new_session_path
    assert_equal "Invalid email or password.", flash[:alert]
  end

  test "DELETE destroy signs out and redirects to login" do
    sign_in managers(:admin)
    delete session_path
    assert_redirected_to new_session_path
  end
end
