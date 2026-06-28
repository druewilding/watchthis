require "application_system_test_case"

class InboxSystemTest < ApplicationSystemTestCase
  setup { sign_in_as users(:alice) }

  test "dashboard shows inbox heading and URL form" do
    visit dashboard_url
    assert_selector "h1", text: "Inbox"
    assert_selector "input[type='url']"
  end

  test "adding a URL creates a share and shows the watch page" do
    visit dashboard_url
    fill_in "URL", with: "https://example.com/great-article"
    click_on "Add to inbox"

    assert_selector "h1", text: "Watch"
    assert_selector "a", text: "Open link"
    assert_selector "button", text: "Mark watched"
  end

  test "YouTube share page shows embedded player" do
    visit share_url(shares(:alice_youtube))
    assert_selector "iframe[src*='youtube.com/embed/dQw4w9WgXcQ']"
    assert_text "Rick Astley"
  end

  test "mark watched from share page redirects to dashboard with notice" do
    visit share_url(shares(:alice_youtube))
    click_on "Mark watched"
    assert_text "Marked as watched"
    assert_current_path dashboard_path
  end

  private

  def sign_in_as(user, password: "password")
    visit new_user_session_url
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign in"
    assert_text "Sign out"
  end
end
