require 'faker'

puts "Cleaning up database..."
Favorite.destroy_all
Recipe.destroy_all
Search.destroy_all
User.destroy_all
puts "Database cleaned!"

user = User.create!(
  email: 'admin@matchmeal.eu',
  password: 'admin@matchmeal.eu',
  first_name: 'Match',
  last_name: 'Meal'
)

puts "Created user: #{user.email}"

3.times do
  Search.create!(
    meal_type: Faker::Food.dish,
    ingredients: Faker::Food.ingredient,
    user: user
  )
end

puts "Created 3 searches for the user"

searches = Search.all

image_urls = [
  "http://chelseawinter.co.nz/wp-content/uploads/2013/09/Fish-Dish-Desat-LensTitlt-Sharpen-light-large.jpg",
  "http://img.taste.com.au/QaDKlckA/taste/2016/11/fresh-summer-vegetable-salad-91664-1.jpeg",
  "https://static.fanpage.it/wp-content/uploads/sites/22/2018/06/istock-529669952.jpg",
  "https://cdn.cnn.com/cnnnext/dam/assets/210211142532-18-classic-italian-dishes-super-tease.jpg",
  "https://sallysbakingaddiction.com/wp-content/uploads/2016/02/easy-peanut-butter-chocolate-lava-cakes-6.jpg"
]

recipe_details = [
  {
    name: "Grilled Fish with Lemon Butter Sauce",
    ingredients: "Fish, Lemon, Butter, Garlic, Parsley",
    description: "A delightful grilled fish recipe served with a rich lemon butter sauce, perfect for seafood lovers."
  },
  {
    name: "Fresh Summer Vegetable Salad",
    ingredients: "Lettuce, Cherry Tomatoes, Cucumber, Bell Peppers, Olive Oil",
    description: "A vibrant and refreshing summer salad with fresh vegetables and a light dressing."
  },
  {
    name: "Rustic Italian Bruschetta",
    ingredients: "Bread, Tomatoes, Basil, Olive Oil, Garlic",
    description: "Crispy toasted bread topped with a fresh tomato and basil mixture, an Italian classic."
  },
  {
    name: "Classic Spaghetti Carbonara",
    ingredients: "Spaghetti, Eggs, Pancetta, Parmesan Cheese, Black Pepper",
    description: "A rich and creamy pasta dish featuring pancetta and a Parmesan-based sauce."
  },
  {
    name: "Chocolate Lava Cake",
    ingredients: "Dark Chocolate, Butter, Sugar, Eggs, Flour",
    description: "A decadent dessert with a gooey molten chocolate center that melts in your mouth."
  }
]

5.times do |i|
  Recipe.create!(
    name: recipe_details[i][:name],
    description: recipe_details[i][:description],
    rating: rand(3..5), # Higher range for better recipes
    ingredients: recipe_details[i][:ingredients],
    cooking_time: rand(20..60), # Realistic cooking times
    search_id: searches.sample.id,
    image: image_urls[i]
  )
end


puts "Created 5 recipes"

recipes = Recipe.all

2.times do
  Favorite.create!(
    user: user,
    recipe: recipes.sample
  )
end

puts "Created 2 favorites for the user"
