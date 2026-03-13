require "test_helper"

class CrewMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
  end

  test "GET index lists tenant crew members" do
    get crew_members_path
    assert_response :success
    assert_match "Callum MacLeod", response.body
    assert_no_match "Jake Williams", response.body
  end

  test "GET new renders form" do
    get new_crew_member_path
    assert_response :success
    assert_select "form"
  end

  test "POST create adds crew member to current account" do
    assert_difference "CrewMember.count", 1 do
      post crew_members_path, params: {
        crew_member: { name: "New Person", role: "Inspector", email: "new@crewboard.com" }
      }
    end
    member = CrewMember.last
    assert_equal accounts(:aberdeen), member.account
  end

  test "POST create with invalid params re-renders" do
    assert_no_difference "CrewMember.count" do
      post crew_members_path, params: { crew_member: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update modifies crew member" do
    patch crew_member_path(crew_members(:callum)), params: {
      crew_member: { role: "Senior Inspector" }
    }
    assert_equal "Senior Inspector", crew_members(:callum).reload.role
  end

  test "DELETE destroy removes crew member" do
    assert_difference "CrewMember.count", -1 do
      delete crew_member_path(crew_members(:callum))
    end
    assert_redirected_to crew_members_path
  end

  test "cannot access other tenant crew member" do
    assert_raises ActiveRecord::RecordNotFound do
      get crew_member_path(crew_members(:other_crew))
    end
  end
end
