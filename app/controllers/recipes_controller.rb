require 'base64'
require 'openai'
require "open-uri"

class RecipesController < ApplicationController
  def index
    api_key = ENV['SPOONACULAR_ACCESS_TOKEN']

    @ingredients = params[:selected_ingredients]&.join(',') || session[:detected_ingredients]

    if @ingredients.nil?
      flash[:error] = "No ingredients detected yet."
      redirect_to detect_ingredients_recipes_path
      return
    end

    url = "https://api.spoonacular.com/recipes/findByIngredients?ingredients=#{@ingredients}&number=10&ranking=1&apiKey=#{api_key}"

    begin
      # Open the URL and parse the JSON response
      @posts = []
      response = URI.parse(url).read
      @posts = JSON.parse(response)
    rescue OpenURI::HTTPError => e
      # Handle errors (e.g., API down, invalid URL)
      @posts = []
      flash[:alert] = "Failed to fetch posts: #{e.message}"
    end
  end

  def show
    api_key = ENV['SPOONACULAR_ACCESS_TOKEN']
    recipe_id = params[:id]

    url = "https://api.spoonacular.com/recipes/#{recipe_id}/information?includeNutrition=true&apiKey=#{api_key}"

    begin
      response = URI.parse(url).read
      @recipe = JSON.parse(response)

    rescue OpenURI::HTTPError => e
      flash[:error] = "Unable to fetch recipe details: #{e.message}"
      redirect_to recipes_path
    end
  end

  def new
    @recipe = Recipe.new
  end

  def create
    unless current_user
      redirect_to new_user_session_path, alert: 'You must be logged in to favorite a recipe.'
      return
    end

    # Fetch the recipe data using Spoonacular API
    api_key = ENV['SPOONACULAR_ACCESS_TOKEN']
    recipe_id = params[:recipe_id]

    url = "https://api.spoonacular.com/recipes/#{recipe_id}/information?apiKey=#{api_key}"

    begin
      response = URI.parse(url).read
      recipe_data = JSON.parse(response)

      # Build the recipe in the database
      @recipe = Recipe.find_or_initialize_by(id: recipe_id)
      @recipe.assign_attributes(
        name: recipe_data["title"],
        description: recipe_data["summary"],
        ingredients: recipe_data["extendedIngredients"]&.map { |i| i["original"] }&.join("\n"),
        cooking_time: recipe_data["readyInMinutes"],
        rating: (recipe_data["spoonacularScore"].to_f / 20).round(1),
        image: recipe_data["image"],
        search_id: Search.first.id # Ensure this matches your schema
      )

      if @recipe.save
        # After saving the recipe, create a favorite for the current user
        current_user.favorites.find_or_create_by(recipe_id: @recipe.id)
        redirect_to recipe_path(@recipe.id), notice: "Recipe saved and favorited successfully!"
      else
        flash[:alert] = "Unable to save recipe: #{@recipe.errors.full_messages.join(', ')}"
        redirect_to recipes_path
      end
    rescue OpenURI::HTTPError => e
      flash[:alert] = "Error fetching recipe data: #{e.message}"
      redirect_to recipes_path
    end
  end

  def detect_ingredients
    # Render the form for uploading an image
  end

  def process_image
    manual_ingredients_input = params[:manual_ingredients].to_s
    manual_ingredients = manual_ingredients_input
      .split(/[,\n]/)
      .map(&:strip)
      .reject(&:blank?)
      .join(', ')

    # Check if an image was uploaded
    if params[:image].blank?
      if manual_ingredients.present?
        session[:detected_ingredients] = manual_ingredients
        redirect_to detect_ingredients_recipes_path, notice: "Ingredients added successfully!"
      else
        flash[:error] = "Please upload an image or enter ingredients manually"
        redirect_to detect_ingredients_recipes_path
      end
      return
    end

    # Read the uploaded file
    uploaded_file = params[:image]

    # Encode the image to base64
    base64_image = Base64.encode64(uploaded_file.read)

    # Initialize OpenAI client
    client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY']
    )

    # Send request to OpenAI
    begin
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: "Identify all the ingredients in this image and provide just the ingredients (do not use numbers or symbols) using comma separated values."
                },
                {
                  type: "image_url",
                  image_url: {
                    url: "data:image/jpeg;base64,#{base64_image}"
                  }
                }
              ]
            }
          ]
        }
      )

      # Extract the content from the response
      @ingredients = response.dig("choices", 0, "message", "content")

      # Store ingredients in the session to pass to the next page
      combined_ingredients = [
        @ingredients,
        manual_ingredients.presence
      ].compact.reject(&:blank?).join(', ')

      session[:detected_ingredients] = combined_ingredients

      # Redirect to the detect_ingredients page with the results
      redirect_to detect_ingredients_recipes_path, notice: "Ingredients detected successfully!"
    rescue StandardError => e
      flash[:error] = "Error processing image: #{e.message}"
      redirect_to detect_ingredients_recipes_path
    end
  end

  private

  def recipe_params
    params.permit(:image)
  end

  # Fetch recipe details from the Spoonacular API
  def fetch_recipe_from_api(recipe_id, api_key)
    url = "https://api.spoonacular.com/recipes/#{recipe_id}/information?apiKey=#{api_key}"

    begin
      response = URI.parse(url).read
      JSON.parse(response)
    rescue OpenURI::HTTPError => e
      Rails.logger.error "API Error: #{e.message}"
      nil
    end
  end

  # Format ingredients into a single string
  def format_ingredients(ingredients)
    return "" unless ingredients
    ingredients.map { |ingredient| ingredient["original"] }.join("\n")
  end

  # Format instructions into a single string
  def format_instructions(instructions)
    return "" unless instructions
    instructions.map do |instruction|
      instruction["steps"].map { |step| step["step"] }.join(" ")
    end.join("\n")
  end

end
