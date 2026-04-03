module ApplicationHelper
  # Spoonacular returns small images (e.g. 312x231) by default.
  # Their CDN supports larger sizes via the filename — swap to 636x393 for desktop clarity.
  SPOONACULAR_IMAGE_SIZES = /\-\d+x\d+(?=\.\w+$)/.freeze

  def spoonacular_image_url(url, size: "636x393")
    return url if url.blank?
    url.sub(SPOONACULAR_IMAGE_SIZES, "-#{size}")
  end
end
