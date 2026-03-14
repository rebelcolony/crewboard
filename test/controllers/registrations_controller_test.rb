require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders signup form" do
    get new_registration_path
    assert_response :success
    assert_select "input[name='account[name]']"
    assert_select "input[name='manager[email_address]']"
  end

  test "POST create with valid params creates account and manager" do
    assert_difference [ "Account.count", "Manager.count" ], 1 do
      post registration_path, params: {
        account: { name: "New Company" },
        manager: {
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to dashboard_path
  end

  test "POST create sends welcome email" do
    assert_enqueued_emails 1 do
      post registration_path, params: {
        account: { name: "Email Test Co" },
        manager: {
          email_address: "welcome@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "POST create with invalid params re-renders form" do
    assert_no_difference "Account.count" do
      post registration_path, params: {
        account: { name: "" },
        manager: {
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
