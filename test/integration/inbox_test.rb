require "test_helper"

class InboxTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "dashboard is accessible to signed-in user" do
    get dashboard_url
    assert_response :success
    assert_select "h1", text: /Inbox/
  end

  test "unauthenticated user is redirected from dashboard" do
    sign_out :user
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "POST /media with new generic URL creates media, share, and inbox item" do
    assert_difference ["Media.count", "Share.count", "ListItem.count"] do
      post media_url, params: {url: "https://example.com/new-article"}
    end
    assert_redirected_to share_url(Share.last)
  end

  test "POST /media with duplicate URL reuses existing media" do
    assert_no_difference "Media.count" do
      assert_difference ["Share.count", "ListItem.count"] do
        post media_url, params: {url: "https://example.com/article"}
      end
    end
  end

  test "POST /media with YouTube URL fetches oEmbed metadata" do
    oembed = '{"title":"Cool Video","thumbnail_url":"https://i.ytimg.com/vi/abc/hq.jpg","author_name":"Cool Channel"}'
    stub_oembed(oembed) do
      post media_url, params: {url: "https://www.youtube.com/watch?v=newyt1234"}
    end
    assert_equal "Cool Video", Media.last.title
    assert_equal "Cool Channel", Media.last.author
  end

  test "GET /shares/:id shows the watch page for an owned share" do
    get share_url(shares(:alice_youtube))
    assert_response :success
    assert_select "iframe[src*='youtube.com/embed']"
  end

  test "PATCH list_item with status=watched marks both share and item as watched" do
    item = list_items(:alice_youtube_item)
    patch list_list_item_url(lists(:alice_inbox), item), params: {status: "watched"}
    assert_redirected_to dashboard_url
    assert_equal "watched", item.reload.status
    assert_equal "watched", shares(:alice_youtube).reload.status
    assert_not_nil item.reload.watched_at
  end
end
