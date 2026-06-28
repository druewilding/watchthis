require "test_helper"

class MediaControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "POST /media with a schemeless URL prepends https and creates media" do
    assert_difference "Media.count" do
      post media_path, params: {url: "github.com/druewilding/watchthis"}
    end
    assert_equal "https://github.com/druewilding/watchthis", Media.order(:created_at).last.normalized_url
  end

  test "POST /media with a schemeless YouTube URL normalises correctly" do
    assert_difference "Media.count" do
      post media_path, params: {url: "youtube.com/watch?v=newvideo99"}
    end
    assert_equal "https://www.youtube.com/watch?v=newvideo99", Media.order(:created_at).last.normalized_url
  end

  test "share page external link uses normalized_url not raw url" do
    get share_path(shares(:alice_article))
    assert_select "a[href=?]", media(:generic_article).normalized_url
  end
end
