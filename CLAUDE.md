# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start development server
rails server

# Database
rails db:create db:migrate db:seed
rails db:migrate
rails db:rollback

# Tests
rails test                  # all tests
rails test test/models/     # model tests only
rails test test/controllers/ # controller tests only
rails test test/system/     # system tests (Capybara/Selenium)
rails test test/models/recipe_test.rb  # single file

# Linting
rubocop        # check
rubocop -a     # auto-fix
```

RuboCop excludes: `bin/`, `db/`, `config/`, `node_modules/`, `test/`, `tmp/`. Max line length is 120.

## Architecture

MatchMeal is a Rails 7.1 + PostgreSQL app where users upload photos of ingredients to get recipe suggestions. The core flow:

1. User uploads an image → `RecipesController#process_image` sends it to **OpenAI GPT-4o-mini** to extract ingredient names
2. Detected ingredients are stored in the session; user selects which to use
3. Selected ingredients are sent to the **Spoonacular API** to fetch matching recipes (`RecipesController#index`)
4. Recipe detail pages fetch full data from Spoonacular on demand (`RecipesController#show`)
5. Users can favorite recipes, which persists them to the local DB (`favorites` table, `Recipe` model)

Manual ingredient entry is also supported in `process_image` as an alternative to image upload.

## Key Models

- **User** — Devise auth, has `first_name`/`last_name`, profile picture via Active Storage
- **Search** — Records a user's search session (meal type + ingredients); `belongs_to :user`
- **Recipe** — Local copy of a Spoonacular recipe; `belongs_to :search`, `has_many :favorites`
- **Favorite** — Join between User and Recipe (`has_many :favorite_recipes, through: :favorites`)

## Key Controllers

- **RecipesController** — Most logic lives here. `detect_ingredients`/`process_image` handle the image→ingredients flow; `index` calls Spoonacular; `show` fetches full recipe details.
- **FavoritesController** — CRUD for user favorites; requires `authenticate_user!`
- **ApplicationController** — Sets `authenticate_user!` globally (except `pages#home`); handles Devise strong params for first/last name

## External Services

All credentials come from environment variables (`.env` via `dotenv-rails` in dev):

| Service | Env var | Purpose |
|---|---|---|
| OpenAI | `OPENAI_API_KEY` | Ingredient detection from images |
| Spoonacular | `SPOONACULAR_ACCESS_TOKEN` | Recipe search and detail API |
| Cloudinary | `CLOUDINARY_URL` | Active Storage image backend |

OpenAI client is initialized in `config/initializers/openai.rb`. Cloudinary is configured in `config/initializers/cloudinary.rb`.

## Frontend

- **Hotwire** (Turbo + Stimulus) for reactive UI without a full SPA
- **Bootstrap 5** + **SimpleForm** with Bootstrap wrappers for forms
- **Importmap** for JS dependency management (no Node/webpack)
- **Font Awesome 6** for icons
