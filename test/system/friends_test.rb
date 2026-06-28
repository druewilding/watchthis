require "application_system_test_case"

class FriendsSystemTest < ApplicationSystemTestCase
  test "sending a friend request shows a pending entry" do
    carol = User.create!(email: "carol@example.com", password: "password")
    carol.lists.create!(name: "Inbox", is_default: true)

    sign_in_as users(:alice)
    visit friendships_url
    fill_in "Email address", with: carol.email
    click_on "Send request"

    assert_text "Friend request sent to carol@example.com."
    assert_text "Waiting for carol@example.com to accept"
  end

  test "accepting a friend request moves them into the friends list" do
    carol = User.create!(email: "carol@example.com", password: "password")
    carol.lists.create!(name: "Inbox", is_default: true)
    Friendship.create!(user: carol, friend: users(:alice), status: "pending")

    sign_in_as users(:alice)
    visit friendships_url

    assert_text "Friend requests"
    assert_text "carol@example.com"
    click_on "Accept"

    assert_text "You're now connected with carol@example.com."
    assert_text "carol@example.com"
    assert_no_text "Friend requests"
  end

  test "sharing a piece of media sends it to a friend" do
    sign_in_as users(:alice)
    visit share_url(shares(:alice_youtube))

    assert_text "Send to a friend"
    select users(:bob).email, from: "Friend"
    fill_in "Message (optional)", with: "thought you'd like this!"
    click_on "Send"

    assert_current_path dashboard_path
    assert_text "Shared with #{users(:bob).email}!"
  end

  private

  def sign_in_as(user, password: "password")
    visit new_user_session_url
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign in"
    assert_current_path root_path
  end
end
