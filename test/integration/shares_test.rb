require "test_helper"

class SharesTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "sharing media with a friend creates a share and adds it to their inbox" do
    assert_difference ["Share.count", "ListItem.count"] do
      post shares_url, params: {share: {media_id: media(:youtube_video).id, to_user_id: users(:bob).id}}
    end
    share = Share.order(:created_at).last
    assert_equal users(:alice), share.from_user
    assert_equal users(:bob), share.to_user
    assert_equal media(:youtube_video), share.media
    assert_equal "pending", share.status
    assert users(:bob).inbox.list_items.where(share: share).exists?
  end

  test "sharing with an optional message stores the message" do
    post shares_url, params: {share: {media_id: media(:youtube_video).id, to_user_id: users(:bob).id, message: "thought you'd like this"}}
    assert_equal "thought you'd like this", Share.order(:created_at).last.message
  end

  test "cannot share with a non-friend" do
    stranger = User.create!(email: "stranger@example.com", password: "password")
    assert_no_difference ["Share.count", "ListItem.count"] do
      post shares_url, params: {share: {media_id: media(:youtube_video).id, to_user_id: stranger.id}}
    end
  end
end
