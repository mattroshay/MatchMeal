require "net/http"

class UnsplashImageService
  CACHE_TTL = 7.days
  BASE_URL  = "https://api.unsplash.com/search/photos"

  def self.fetch(recipe_title)
    new(recipe_title).fetch
  end

  # Must be called when a user views/uses a photo — Unsplash API requirement.
  def self.trigger_download(download_location)
    return if download_location.blank?
    Thread.new do
      uri = URI(download_location)
      uri.query = [uri.query, URI.encode_www_form(client_id: ENV["UNSPLASH_ACCESS_KEY"])].compact.join("&")
      Net::HTTP.get_response(uri)
    rescue StandardError => e
      Rails.logger.warn("UnsplashImageService download trigger failed: #{e.message}")
    end
  end

  def initialize(recipe_title)
    @recipe_title = recipe_title
  end

  def fetch
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_from_unsplash }
  end

  private

  def cache_key
    "unsplash/#{@recipe_title.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')}"
  end

  def fetch_from_unsplash
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(
      query:          @recipe_title,
      per_page:       1,
      orientation:    "landscape",
      content_filter: "high",
      client_id:      ENV["UNSPLASH_ACCESS_KEY"]
    )
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    result = JSON.parse(response.body).dig("results", 0)
    return nil if result.nil?

    {
      regular:           result.dig("urls", "regular"),
      small:             result.dig("urls", "small"),
      download_location: result.dig("links", "download_location"),
      photographer_name: result.dig("user", "name"),
      photographer_url:  result.dig("user", "links", "html")
    }
  rescue StandardError => e
    Rails.logger.warn("UnsplashImageService failed for '#{@recipe_title}': #{e.message}")
    nil
  end
end
