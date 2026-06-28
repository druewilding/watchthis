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
      metadata = youtube_id ? fetch_oembed(url) : {}

      create!(
        url: url,
        normalized_url: normalized,
        platform: platform,
        youtube_id: youtube_id,
        title: metadata[:title],
        thumbnail_url: metadata[:thumbnail_url],
        author: metadata[:author],
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
  end
end
