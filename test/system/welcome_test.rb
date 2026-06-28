require "application_system_test_case"

class WelcomeTest < ApplicationSystemTestCase
  test "welcome page renders the full klods layout" do
    visit root_url

    assert_selector "div.klods-page"
    assert_selector "header.klods-header"
    # sidebar may be CSS-hidden on narrow viewports; check it exists in the DOM
    assert_selector "aside.klods-sidebar", visible: :all
    assert_selector "main.klods-content"
    assert_selector "footer.klods-footer"
  end

  test "page has the correct title" do
    visit root_url
    assert_title "Rails Server Template"
  end

  test "welcome heading is visible" do
    visit root_url
    assert_text "Welcome!"
  end

  test "sidebar toggle button is present in the DOM" do
    visit root_url
    # toggle is CSS-hidden on wide viewports; check it exists in the DOM
    assert_selector "button.klods-sidebar-toggle", visible: :all
  end

  test "API status button navigates to the status endpoint" do
    visit root_url
    click_on "API status"
    assert_current_path "/api/v1/status"
  end
end
