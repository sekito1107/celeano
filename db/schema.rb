# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_09_164237) do
  create_table "battle_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "logs"
    t.integer "turn_id", null: false
    t.datetime "updated_at", null: false
    t.index ["turn_id"], name: "index_battle_logs_on_turn_id"
  end

  create_table "cards", force: :cascade do |t|
    t.string "attack"
    t.integer "card_type"
    t.string "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "flavor_text"
    t.integer "hp"
    t.string "image_name"
    t.string "keyword"
    t.string "madness_param"
    t.text "madness_text"
    t.string "name"
    t.integer "sanity_threshold"
    t.datetime "updated_at", null: false
  end

  create_table "game_cards", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_hp"
    t.integer "game_id", null: false
    t.integer "position"
    t.json "status_effects"
    t.integer "summoned_turn"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["card_id"], name: "index_game_cards_on_card_id"
    t.index ["game_id"], name: "index_game_cards_on_game_id"
    t.index ["user_id"], name: "index_game_cards_on_user_id"
  end

  create_table "game_players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "deck_data"
    t.integer "game_id", null: false
    t.json "graveyard_data"
    t.json "hand_data"
    t.integer "hp"
    t.integer "role"
    t.integer "san"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id"], name: "index_game_players_on_game_id"
    t.index ["user_id"], name: "index_game_players_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "finish_reason"
    t.datetime "finished_at"
    t.integer "loser_id"
    t.integer "seed"
    t.integer "status"
    t.integer "turn_count"
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["loser_id"], name: "index_games_on_loser_id"
    t.index ["winner_id"], name: "index_games_on_winner_id"
  end

  create_table "moves", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "turn_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["card_id"], name: "index_moves_on_card_id"
    t.index ["turn_id"], name: "index_moves_on_turn_id"
    t.index ["user_id"], name: "index_moves_on_user_id"
  end

  create_table "turns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "status"
    t.integer "turn_number"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_turns_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "role"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "battle_logs", "turns"
  add_foreign_key "game_cards", "cards"
  add_foreign_key "game_cards", "games"
  add_foreign_key "game_cards", "users"
  add_foreign_key "game_players", "games"
  add_foreign_key "game_players", "users"
  add_foreign_key "games", "users", column: "loser_id"
  add_foreign_key "games", "users", column: "winner_id"
  add_foreign_key "moves", "cards"
  add_foreign_key "moves", "turns"
  add_foreign_key "moves", "users"
  add_foreign_key "turns", "games"
end
