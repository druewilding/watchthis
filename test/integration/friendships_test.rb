require "test_helper"

class FriendshipsTest < ActionDispatch::IntegrationTest
  test "sending a friend request creates a pending friendship" do
    sign_in users(:alice)
    carol = User.create!(email: "carol@example.com", password: "password")
    assert_difference "Friendship.count" do
      post friendships_url, params: {email: carol.email}
    end
    assert_redirected_to friendships_url
    friendship = Friendship.order(:created_at).last
    assert_equal users(:alice), friendship.user
    assert_equal carol, friendship.friend
    assert_equal "pending", friendship.status
  end

  test "cannot send a friend request to yourself" do
    sign_in users(:alice)
    assert_no_difference "Friendship.count" do
      post friendships_url, params: {email: users(:alice).email}
    end
    assert_redirected_to friendships_url
  end

  test "cannot send a duplicate friend request" do
    sign_in users(:alice)
    assert_no_difference "Friendship.count" do
      post friendships_url, params: {email: users(:bob).email}
    end
    assert_redirected_to friendships_url
  end

  test "accepting a friend request updates status to accepted" do
    carol = User.create!(email: "carol@example.com", password: "password")
    carol.lists.create!(name: "Inbox", is_default: true)
    friendship = Friendship.create!(user: carol, friend: users(:alice), status: "pending")

    sign_in users(:alice)
    patch friendship_url(friendship)
    assert_redirected_to friendships_url
    assert_equal "accepted", friendship.reload.status
  end

  test "sender cannot accept their own outgoing request" do
    carol = User.create!(email: "carol@example.com", password: "password")
    carol.lists.create!(name: "Inbox", is_default: true)
    friendship = Friendship.create!(user: users(:alice), friend: carol, status: "pending")

    sign_in users(:alice)
    patch friendship_url(friendship)
    assert_redirected_to friendships_url
    assert_equal "pending", friendship.reload.status
  end

  test "removing a friend destroys the friendship" do
    sign_in users(:alice)
    assert_difference "Friendship.count", -1 do
      delete friendship_url(friendships(:alice_bob))
    end
    assert_redirected_to friendships_url
  end
end
