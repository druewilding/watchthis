require "application_system_test_case"

class WelcomeTest < ApplicationSystemTestCase
  test "welcome page renders the klods layout without a sidebar" do
    visit root_url

    assert_selector "div.klods-page"
    assert_selector "header.klods-header"
    assert_no_selector "aside.klods-sidebar"
    assert_selector "main.klods-content"
    assert_selector "footer.klods-footer"
  end

  test "page has the correct title" do
    visit root_url
    assert_title "WatchThis"
  end

  test "welcome heading is visible" do
    visit root_url
    assert_text "WatchThis"
  end

  test "nav shows sign in and sign up links" do
    visit root_url
    assert_selector "a[href='/users/sign_in']", text: "Sign in"
    assert_selector "a[href='/users/sign_up']", text: "Sign up"
  end

  test "create an account button navigates to sign up" do
    visit root_url
    click_on "Create an account"
    assert_current_path "/users/sign_up"
  end

  test "sign in button navigates to sign in page" do
    visit root_url
    find(".klods-button", text: "Sign in").click
    assert_current_path "/users/sign_in"
  end
end
