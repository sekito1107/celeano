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

ActiveRecord::Schema[8.1].define(version: 2026_01_15_233109) do
  create_table "battle_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "details", default: {}, null: false
    t.string "event_type", null: false
    t.integer "turn_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_battle_logs_on_event_type"
    t.index ["turn_id"], name: "index_battle_logs_on_turn_id"
  end

  create_table "card_keywords", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "keyword_id", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "keyword_id"], name: "index_card_keywords_on_card_id_and_keyword_id", unique: true
    t.index ["card_id"], name: "index_card_keywords_on_card_id"
    t.index ["keyword_id"], name: "index_card_keywords_on_keyword_id"
  end

  create_table "cards", force: :cascade do |t|
    t.string "attack", default: "0", null: false
    t.integer "card_type", default: 0, null: false
    t.string "cost", default: "0", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "hp", default: 0, null: false
    t.string "image_name"
    t.string "key_code", null: false
    t.string "name", null: false
    t.integer "threshold_san", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key_code"], name: "index_cards_on_key_code", unique: true
  end

  create_table "game_card_modifiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration"
    t.integer "effect_type", null: false
    t.integer "game_card_id", null: false
    t.integer "modification_type", null: false
    t.string "source_name"
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["game_card_id"], name: "index_game_card_modifiers_on_game_card_id"
  end

  create_table "game_cards", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.string "current_attack", default: "0", null: false
    t.integer "current_hp", null: false
    t.integer "game_id", null: false
    t.integer "game_player_id", null: false
    t.integer "location", default: 0, null: false
    t.integer "position"
    t.integer "position_in_stack"
    t.integer "summoned_turn"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["card_id"], name: "index_game_cards_on_card_id"
    t.index ["game_id", "user_id", "location", "position_in_stack"], name: "idx_on_game_id_user_id_location_position_in_stack_51f28a9f5c"
    t.index ["game_id", "user_id", "location"], name: "index_game_cards_on_game_id_and_user_id_and_location"
    t.index ["game_id"], name: "index_game_cards_on_game_id"
    t.index ["game_player_id", "location"], name: "index_game_cards_on_game_player_id_and_location"
    t.index ["game_player_id"], name: "index_game_cards_on_game_player_id"
    t.index ["user_id"], name: "index_game_cards_on_user_id"
  end

  create_table "game_players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "deck_type"
    t.integer "game_id", null: false
    t.integer "hp", default: 20, null: false
    t.boolean "ready", default: false, null: false
    t.integer "role", default: 0, null: false
    t.integer "san", default: 20, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id", "user_id"], name: "index_game_players_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_game_players_on_game_id"
    t.index ["user_id"], name: "index_game_players_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "finish_reason"
    t.datetime "finished_at"
    t.integer "loser_id"
    t.integer "seed", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["loser_id"], name: "index_games_on_loser_id"
    t.index ["winner_id"], name: "index_games_on_winner_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_keywords_on_name", unique: true
  end

  create_table "moves", force: :cascade do |t|
    t.integer "action_type", null: false
    t.datetime "created_at", null: false
    t.integer "game_card_id", null: false
    t.integer "position"
    t.integer "target_game_card_id"
    t.integer "target_player_id"
    t.integer "turn_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["action_type"], name: "index_moves_on_action_type"
    t.index ["game_card_id"], name: "index_moves_on_game_card_id"
    t.index ["target_game_card_id"], name: "index_moves_on_target_game_card_id"
    t.index ["target_player_id"], name: "index_moves_on_target_player_id"
    t.index ["turn_id"], name: "index_moves_on_turn_id"
    t.index ["user_id"], name: "index_moves_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "turns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "turn_number", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "turn_number"], name: "index_turns_on_game_id_and_turn_number", unique: true
    t.index ["game_id"], name: "index_turns_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", default: "", null: false
    t.string "name", null: false
    t.string "password_digest", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "battle_logs", "turns"
  add_foreign_key "card_keywords", "cards"
  add_foreign_key "card_keywords", "keywords"
  add_foreign_key "game_card_modifiers", "game_cards"
  add_foreign_key "game_cards", "cards"
  add_foreign_key "game_cards", "game_players"
  add_foreign_key "game_cards", "games"
  add_foreign_key "game_cards", "users"
  add_foreign_key "game_players", "games"
  add_foreign_key "game_players", "users"
  add_foreign_key "games", "users", column: "loser_id"
  add_foreign_key "games", "users", column: "winner_id"
  add_foreign_key "moves", "game_cards"
  add_foreign_key "moves", "game_cards", column: "target_game_card_id"
  add_foreign_key "moves", "game_players", column: "target_player_id"
  add_foreign_key "moves", "turns"
  add_foreign_key "moves", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "turns", "games"
end
