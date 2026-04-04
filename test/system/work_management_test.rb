require "application_system_test_case"

class WorkManagementTest < ApplicationSystemTestCase
  test "create a project from the projects page" do
    subscribe_account_to!("starter")
    system_sign_in

    click_on "Projects"
    click_on "New Project"
    fill_in "Name", with: "Tyra West Inspection"
    fill_in "Location", with: "North Sea"
    select "In progress", from: "Status"
    fill_in "Progress (%)", with: "25"
    click_on "Create Project"

    assert_text "Project created."
    assert_text "Tyra West Inspection"
  end

  test "open a project card from the dashboard in the modal" do
    system_sign_in

    click_on "Forties Alpha Inspection"

    assert_text "Crew (1)"
    assert_text "Callum MacLeod"
  end

  test "update a project from the dashboard modal with inline autosave" do
    system_sign_in

    click_on "Forties Alpha Inspection"

    update_modal_field "input[name='project[name]']", "Forties Alpha Phase 2"
    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_text "Forties Alpha Phase 2"
    end

    update_modal_field "input[name='project[location]']", "Central North Sea"
    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_text "Central North Sea"
    end

    update_modal_select "select[name='project[status]']", "Completed"
    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_text "COMPLETED"
    end

    update_modal_progress "input[name='project[progress]']", 80
    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_text "80%"
    end

    within "turbo-frame#modal" do
      assert_selector "input[name='project[name]'][value='Forties Alpha Phase 2']"
      assert_selector "input[name='project[location]'][value='Central North Sea']"
      assert_selector ".inline-progress-value", text: "80%"
      assert_select_value "select[name='project[status]']", "completed"
    end

    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_text "Forties Alpha Phase 2"
      assert_text "Central North Sea"
      assert_text "COMPLETED"
      assert_text "80%"
    end
  end

  test "reassign crew from the unassigned bar onto a project card" do
    system_sign_in

    assert_text "Unassigned Crew (1)"
    assert_selector "#unassigned-crew img[alt='Isla Campbell']"

    drag_crew_member_to_project(crew_members(:unassigned_isla), projects(:forties))

    assert_text "Unassigned Crew (0)"
    assert_text "All crew members assigned"
    assert_no_selector "#unassigned-crew img[alt='Isla Campbell']"

    within "turbo-frame#project_#{projects(:forties).id}" do
      assert_selector "img[alt='Isla Campbell']"
      assert_selector "img[alt='Callum MacLeod']"
    end
  end

  test "add a crew member from the crew page" do
    system_sign_in

    click_on "Crew"
    click_on "Add Crew Member"
    fill_in "Name", with: "Mairi Fraser"
    fill_in "Role", with: "ROV Pilot"
    fill_in "Email", with: "mairi@example.com"
    select "Forties Alpha Inspection", from: "Assigned Project"
    click_button "Create Crew member"

    assert_text "Crew member added."
    assert_text "Mairi Fraser"
    assert_text "Forties Alpha Inspection"
  end

  test "delete a project from the projects page" do
    system_sign_in

    click_on "Projects"

    within "tr", text: "Brent Delta Decommissioning" do
      accept_confirm do
        click_on "Delete"
      end
    end

    assert_text "Project deleted."
    assert_no_text "Brent Delta Decommissioning"
  end

  test "delete a crew member from the crew page" do
    system_sign_in

    click_on "Crew"

    within "tr", text: "Callum MacLeod" do
      accept_confirm do
        click_on "Delete"
      end
    end

    assert_text "Crew member removed."
    assert_no_text "Callum MacLeod"
  end

  private

  def update_modal_field(selector, value)
    within "turbo-frame#modal" do
      find(selector).set(value)
    end
  end

  def update_modal_select(selector, value)
    within "turbo-frame#modal" do
      find(selector).select(value)
    end
  end

  def update_modal_progress(selector, value)
    within "turbo-frame#modal" do
      slider = find(selector, visible: :all)
      page.execute_script(<<~JS, slider.native, value)
        const input = arguments[0]
        input.value = arguments[1]
        input.dispatchEvent(new Event("input", { bubbles: true }))
      JS
    end
  end

  def drag_crew_member_to_project(member, project)
    page.execute_script(<<~JS, member.id, project.id)
      const source = document.querySelector(`[data-draggable-crew-member-id-value="${arguments[0]}"]`)
      const target = document.querySelector(`[data-drop-target-project-id-value="${arguments[1]}"]`)
      const dataTransfer = new DataTransfer()

      source.dispatchEvent(new DragEvent("dragstart", { bubbles: true, dataTransfer }))
      target.dispatchEvent(new DragEvent("dragover", { bubbles: true, cancelable: true, dataTransfer }))
      target.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer }))
      source.dispatchEvent(new DragEvent("dragend", { bubbles: true, dataTransfer }))
    JS
  end

  def assert_select_value(selector, value)
    assert_equal value, find(selector).value
  end
end
