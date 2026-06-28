require "test_helper"

class MediaTest < ActiveSupport::TestCase
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

  test "youtube? is true for YouTube media" do
    assert media(:youtube_video).youtube?
  end

  test "youtube? is false for generic media" do
    refute media(:generic_article).youtube?
  end

  test "embed_url returns YouTube embed URL" do
    assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ", media(:youtube_video).embed_url
  end

  test "embed_url is nil for generic media" do
    assert_nil media(:generic_article).embed_url
  end

  test "find_or_create_from_url returns existing record for duplicate URL" do
    existing = media(:generic_article)
    assert_no_difference "Media.count" do
      result = Media.find_or_create_from_url("https://example.com/article", added_by: users(:alice))
      assert_equal existing, result
    end
  end

  test "find_or_create_from_url creates new record for unseen generic URL" do
    stub_og_fetch(nil) do
      assert_difference "Media.count" do
        Media.find_or_create_from_url("https://example.com/brand-new-page", added_by: users(:alice))
      end
    end
  end

  test "find_or_create_from_url parses article:published_time for generic URL" do
    html = '<meta property="article:published_time" content="2026-06-28T10:00:00+00:00">'
    stub_og_fetch(html) do
      media = Media.find_or_create_from_url("https://example.com/dated-article", added_by: users(:alice))
      assert_equal Time.zone.parse("2026-06-28T10:00:00+00:00"), media.published_at
    end
  end

  test "find_or_create_from_url parses datePublished itemprop for YouTube" do
    oembed = '{"title":"Test Video","thumbnail_url":"https://i.ytimg.com/vi/xyz/hq.jpg","author_name":"Test Channel"}'
    html = '<meta itemprop="datePublished" content="2026-01-15">'
    stub_og_fetch(html) do
      stub_oembed(oembed) do
        media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid789", added_by: users(:alice))
        assert_equal Time.zone.parse("2026-01-15"), media.published_at
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
      media = Media.find_or_create_from_url("https://www.dr.dk/nyheder/vejret/varme-og-hedeboelge-over-europa", added_by: users(:alice))
      assert_equal "Varme og hedebølge over Europa", media.title
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
        media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid123", added_by: users(:alice))
        assert_equal "Test Video", media.title
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
        media = Media.find_or_create_from_url("https://www.youtube.com/watch?v=newvid456", added_by: users(:alice))
        assert_equal "Test Video", media.title
        assert_equal "Test Channel", media.author
        assert_equal "A great video about things", media.description
      end
    end
  end
end
