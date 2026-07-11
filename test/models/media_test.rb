require "test_helper"

class MediaTest < ActiveSupport::TestCase
  test "normalises URL with no scheme by prepending https://" do
    assert_equal "https://example.com/article",
      Media.send(:normalize, "example.com/article")
  end

  test "normalises YouTube URL with no scheme" do
    assert_equal "https://www.youtube.com/watch?v=abc123",
      Media.send(:normalize, "youtube.com/watch?v=abc123")
  end

  test "normalises youtu.be short URL with no scheme" do
    assert_equal "https://www.youtube.com/watch?v=abc123",
      Media.send(:normalize, "youtu.be/abc123")
  end

  test "leaves http:// URLs alone" do
    assert_equal "http://example.com/article",
      Media.send(:normalize, "http://example.com/article")
  end

  test "normalises youtube.com watch URL by stripping extra params" do
    assert_equal "https://www.youtube.com/watch?v=abc123",
      Media.send(:normalize, "https://www.youtube.com/watch?v=abc123&feature=share")
  end

  test "normalises YouTube Shorts URL to standard watch URL" do
    assert_equal "https://www.youtube.com/watch?v=PEinSc4U_lk",
      Media.send(:normalize, "https://www.youtube.com/shorts/PEinSc4U_lk")
  end

  test "normalises youtu.be short URL to long form" do
    assert_equal "https://www.youtube.com/watch?v=abc123",
      Media.send(:normalize, "https://youtu.be/abc123")
  end

  test "normalises generic URL by stripping query string and fragment" do
    assert_equal "https://example.com/article",
      Media.send(:normalize, "https://example.com/article?ref=twitter#section")
  end

  test "normalises Instagram URL by stripping tracking params" do
    assert_equal "https://www.instagram.com/p/ABC123/",
      Media.send(:normalize, "https://www.instagram.com/p/ABC123/?igsh=xyz&utm_source=ig_web_copy_link")
  end

  test "normalises Instagram reel URL by stripping tracking params" do
    assert_equal "https://www.instagram.com/reel/DEF456/",
      Media.send(:normalize, "https://www.instagram.com/reel/DEF456/?igsh=xyz")
  end

  test "normalises instagr.am short domain to instagram.com" do
    assert_equal "https://www.instagram.com/p/ABC123/",
      Media.send(:normalize, "https://instagr.am/p/ABC123/")
  end

  test "normalises TikTok URL by stripping tracking params" do
    assert_equal "https://www.tiktok.com/@user/video/7418649950270607622",
      Media.send(:normalize, "https://www.tiktok.com/@user/video/7418649950270607622?is_from_webapp=1&sender_device=pc")
  end

  test "normalises mobile TikTok domain to www" do
    assert_equal "https://www.tiktok.com/@user/video/7418649950270607622",
      Media.send(:normalize, "https://m.tiktok.com/@user/video/7418649950270607622")
  end

  test "youtube? is true for YouTube media" do
    assert media(:youtube_video).youtube?
  end

  test "youtube? is false for generic media" do
    refute media(:generic_article).youtube?
  end

  test "instagram? is true for Instagram media" do
    assert media(:instagram_post).instagram?
  end

  test "instagram? is false for non-Instagram media" do
    refute media(:youtube_video).instagram?
  end

  test "tiktok? is true for TikTok media" do
    assert media(:tiktok_video).tiktok?
  end

  test "tiktok? is false for non-TikTok media" do
    refute media(:generic_article).tiktok?
  end

  test "embed_url returns YouTube embed URL" do
    assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ", media(:youtube_video).embed_url
  end

  test "embed_url returns Instagram embed URL for a post" do
    assert_equal "https://www.instagram.com/p/ABC123/embed/", media(:instagram_post).embed_url
  end

  test "embed_url returns Instagram embed URL for a reel" do
    reel = media(:instagram_post).dup
    reel.normalized_url = "https://www.instagram.com/reel/DEF456/"
    assert_equal "https://www.instagram.com/p/DEF456/embed/", reel.embed_url
  end

  test "embed_url returns TikTok embed URL" do
    assert_equal "https://www.tiktok.com/embed/v2/7418649950270607622", media(:tiktok_video).embed_url
  end

  test "embed_url returns nil for TikTok short URL without video ID" do
    short = media(:tiktok_video).dup
    short.normalized_url = "https://vm.tiktok.com/ZMxxxxxx/"
    assert_nil short.embed_url
  end

  test "embed_url is nil for generic media" do
    assert_nil media(:generic_article).embed_url
  end

  test "find_or_create_from_url creates instagram media with correct platform" do
    assert_difference "Media.count" do
      assert_enqueued_with(job: FetchMediaMetadataJob) do
        media = Media.find_or_create_from_url("https://www.instagram.com/p/XYZ999/?igsh=abc", added_by: users(:alice))
        assert_equal "instagram", media.platform
        assert_equal "https://www.instagram.com/p/XYZ999/", media.normalized_url
      end
    end
  end

  test "find_or_create_from_url creates tiktok media with correct platform" do
    assert_difference "Media.count" do
      assert_enqueued_with(job: FetchMediaMetadataJob) do
        media = Media.find_or_create_from_url("https://www.tiktok.com/@someone/video/9999999999?is_from_webapp=1", added_by: users(:alice))
        assert_equal "tiktok", media.platform
        assert_equal "https://www.tiktok.com/@someone/video/9999999999", media.normalized_url
      end
    end
  end

  test "find_or_create_from_url fetches TikTok metadata via oEmbed" do
    oembed = '{"title":"Funny Cat Video","thumbnail_url":"https://p16.tiktokcdn.com/thumb.jpg","author_name":"@cataccount"}'
    stub_og_fetch(nil) do
      stub_oembed(oembed) do
        media = nil
        perform_enqueued_jobs { media = Media.find_or_create_from_url("https://www.tiktok.com/@cataccount/video/1122334455", added_by: users(:alice)) }
        assert_equal "Funny Cat Video", media.reload.title
        assert_equal "@cataccount", media.author
        assert_equal "https://p16.tiktokcdn.com/thumb.jpg", media.thumbnail_url
        assert_equal "tiktok", media.platform
      end
    end
  end

  test "find_or_create_from_url returns existing record for duplicate URL" do
    existing = media(:generic_article)
    assert_no_difference "Media.count" do
      result = Media.find_or_create_from_url("https://example.com/article", added_by: users(:alice))
      assert_equal existing, result
    end
  end

  test "find_or_create_from_url creates new record for unseen URL and enqueues metadata job" do
    assert_difference "Media.count" do
      assert_enqueued_with(job: FetchMediaMetadataJob) do
        Media.find_or_create_from_url("https://example.com/brand-new-page", added_by: users(:alice))
      end
    end
  end

  test "find_or_create_from_url parses article:published_time via name attribute" do
    html = '<meta name="article:published_time" content="2026-06-28T12:28:15.679Z">'
    stub_og_fetch(html) do
      media = nil
      perform_enqueued_jobs { media = Media.find_or_create_from_url("https://example.com/named-article", added_by: users(:alice)) }
      assert_equal Time.zone.parse("2026-06-28T12:28:15.679Z"), media.reload.published_at
    end
  end

  test "find_or_create_from_url parses article:published_time for generic URL" do
    html = '<meta property="article:published_time" content="2026-06-28T10:00:00+00:00">'
    stub_og_fetch(html) do
      media = nil
      perform_enqueued_jobs { media = Media.find_or_create_from_url("https://example.com/dated-article", added_by: users(:alice)) }
      assert_equal Time.zone.parse("2026-06-28T10:00:00+00:00"), media.reload.published_at
    end
  end

  test "find_or_create_from_url parses datePublished itemprop for YouTube" do
    oembed = '{"title":"Test Video","thumbnail_url":"https://i.ytimg.com/vi/xyz/hq.jpg","author_name":"Test Channel"}'
    html = '<meta itemprop="datePublished" content="2026-01-15">'
    stub_og_fetch(html) do
      stub_oembed(oembed) do
        media = nil
        perform_enqueued_jobs { media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid789", added_by: users(:alice)) }
        assert_equal Time.zone.parse("2026-01-15"), media.reload.published_at
      end
    end
  end

  test "find_or_create_from_url fetches OG metadata for generic URL" do
    html = <<~HTML
      <html><head>
        <meta property="og:title" content="Varme og hedebølge over Europa">
        <meta property="og:description" content="Her er vejrudsigten for den kommende uge.">
        <meta property="og:image" content="https://www.dr.dk/image.jpg">
        <meta property="og:site_name" content="DR">
      </head></html>
    HTML
    stub_og_fetch(html) do
      media = nil
      perform_enqueued_jobs { media = Media.find_or_create_from_url("https://www.dr.dk/nyheder/vejret/varme-og-hedeboelge-over-europa", added_by: users(:alice)) }
      assert_equal "Varme og hedebølge over Europa", media.reload.title
      assert_equal "Her er vejrudsigten for den kommende uge.", media.description
      assert_equal "https://www.dr.dk/image.jpg", media.thumbnail_url
      assert_equal "DR", media.site_name
      assert_equal "generic", media.platform
    end
  end

  test "find_or_create_from_url fetches YouTube metadata via oEmbed" do
    oembed = '{"title":"Test Video","thumbnail_url":"https://i.ytimg.com/vi/xyz/hq.jpg","author_name":"Test Channel"}'
    stub_og_fetch(nil) do
      stub_oembed(oembed) do
        media = nil
        perform_enqueued_jobs { media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid123", added_by: users(:alice)) }
        assert_equal "Test Video", media.reload.title
        assert_equal "Test Channel", media.author
        assert_equal "youtube", media.platform
      end
    end
  end

  test "find_or_create_from_url fetches description from OG metadata for YouTube" do
    oembed = '{"title":"Test Video","thumbnail_url":"https://i.ytimg.com/vi/xyz/hq.jpg","author_name":"Test Channel"}'
    html = '<meta property="og:description" content="A great video about things">'
    stub_og_fetch(html) do
      stub_oembed(oembed) do
        media = nil
        perform_enqueued_jobs { media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid456", added_by: users(:alice)) }
        assert_equal "Test Video", media.reload.title
        assert_equal "Test Channel", media.author
        assert_equal "A great video about things", media.description
      end
    end
  end
end
