require "json"
require "cgi"
require "net/http"

class Media < ApplicationRecord
  belongs_to :added_by, class_name: "User"
  has_many :shares, dependent: :destroy
  has_many :list_items, dependent: :destroy

  validates :url, presence: true
  validates :normalized_url, presence: true, uniqueness: true
  validates :platform, presence: true

  def youtube?
    platform == "youtube"
  end

  def embed_url
    "https://www.youtube.com/embed/#{youtube_id}" if youtube?
  end

  class << self
    def find_or_create_from_url(url, added_by:)
      normalized = normalize(url)
      find_by(normalized_url: normalized) || create_from_url(url, normalized, added_by:)
    end

    private

    def create_from_url(url, normalized, added_by:)
      youtube_id = extract_youtube_id(normalized)
      platform = youtube_id ? "youtube" : "generic"
      metadata = if youtube_id
        fetch_og_metadata(url).merge(fetch_oembed(url))
      else
        fetch_og_metadata(url)
      end

      create!(
        url: url,
        normalized_url: normalized,
        platform: platform,
        youtube_id: youtube_id,
        title: metadata[:title],
        thumbnail_url: metadata[:thumbnail_url],
        author: metadata[:author],
        description: metadata[:description],
        site_name: metadata[:site_name],
        added_by: added_by
      )
    end

    def normalize(url)
      uri = URI.parse(url.strip)
      uri.scheme = uri.scheme&.downcase
      uri.host = uri.host&.downcase

      if uri.host&.match?(/youtu\.be/)
        id = uri.path.delete_prefix("/")
        return "https://www.youtube.com/watch?v=#{id}"
      end

      if uri.host&.match?(/youtube\.com/) && uri.path == "/watch"
        params = URI.decode_www_form(uri.query.to_s).to_h
        return "https://www.youtube.com/watch?v=#{params["v"]}" if params["v"]
      end

      uri.query = nil
      uri.fragment = nil
      uri.to_s
    end

    def extract_youtube_id(normalized_url)
      params = URI.decode_www_form(URI.parse(normalized_url).query.to_s).to_h
      params["v"].presence
    end

    def fetch_oembed(url)
      oembed_uri = URI("https://www.youtube.com/oembed?url=#{CGI.escape(url)}&format=json")
      response = Net::HTTP.get(oembed_uri)
      data = JSON.parse(response)
      {title: data["title"], thumbnail_url: data["thumbnail_url"], author: data["author_name"]}
    rescue
      {}
    end

    def fetch_og_metadata(url)
      html = fetch_html(url)
      return {} unless html
      {
        title: og_tag(html, "title"),
        description: og_tag(html, "description"),
        thumbnail_url: og_tag(html, "image"),
        site_name: og_tag(html, "site_name")
      }.compact
    rescue
      {}
    end

    def fetch_html(url, redirects_left = 3)
      return nil if redirects_left == 0
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 5
      http.read_timeout = 10
      req = Net::HTTP::Get.new(uri.request_uri)
      req["User-Agent"] = "Mozilla/5.0 (compatible; WatchThis/1.0)"
      req["Accept"] = "text/html,application/xhtml+xml"
      response = http.request(req)
      case response
      when Net::HTTPSuccess then response.body
      when Net::HTTPRedirection then fetch_html(response["location"], redirects_left - 1)
      end
    rescue
      nil
    end

    def og_tag(html, property)
      tag = html.match(/<meta\b[^>]*\bproperty=["']og:#{Regexp.escape(property)}["'][^>]*>/i)&.to_s
      return unless tag
      content = tag.match(/\bcontent="([^"]*)"/) || tag.match(/\bcontent='([^']*)'/)
      CGI.unescapeHTML(content[1]).presence if content
    end
  end
end
