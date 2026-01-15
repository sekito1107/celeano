# カードデータのインポートタスク
namespace :cards do
  desc "db/data/cards/*.yml からカードデータをDBにインポートする"
  task import: :environment do
    require "yaml"

    sync_keywords = ->(card, keyword_names) do
      # 既存のキーワード関連を削除
      card.card_keywords.destroy_all

      # 新しいキーワードを関連付け
      keyword_names.each do |keyword_name|
        keyword = Keyword.find_or_create_by!(name: keyword_name)
        card.card_keywords.create!(keyword: keyword)
      end
    end

    cards_dir = Rails.root.join("db", "data", "cards")
    imported_count = 0
    updated_count = 0
    error_count = 0

    Dir.glob(cards_dir.join("*.yml")).each do |file_path|
      puts "Loading: #{File.basename(file_path)}"

      cards_data = YAML.safe_load_file(file_path, permitted_classes: [ Symbol ])

      cards_data.values.each do |card_data|
        begin
          card = Card.find_or_initialize_by(key_code: card_data["key_code"])
          is_new = card.new_record?

          card.assign_attributes(
            name: card_data["name"],
            card_type: card_data["card_type"],
            cost: card_data["cost"],
            hp: card_data["hp"] || 0,
            attack: card_data["attack"] || "0"
          )

          ActiveRecord::Base.transaction do
            card.save!

            # キーワードの同期
            sync_keywords.call(card, card_data["keywords"] || [])

            if is_new
              imported_count += 1
              puts "  + Created: #{card.name} (#{card.key_code})"
            else
              updated_count += 1
              puts "  ~ Updated: #{card.name} (#{card.key_code})"
            end
          end
        rescue StandardError => e
          error_count += 1
          puts "  ! Error: #{card_data['key_code']} - #{e.message}"
          puts "    #{e.backtrace.first(3).join("\n    ")}" if ENV["DEBUG"]
        end
      end
    end

    puts ""
    puts "=== Import Complete ==="
    puts "  Created: #{imported_count}"
    puts "  Updated: #{updated_count}"
    puts "  Errors:  #{error_count}"
  end

  desc "インポートされたカード一覧を表示する"
  task list: :environment do
    puts "=== Registered Cards ==="
    Card.includes(:keywords).order(:card_type, :cost, :name).each do |card|
      keywords = card.keywords.map(&:name).join(", ")
      keywords_display = keywords.present? ? " [#{keywords}]" : ""
      puts "  [#{card.card_type}] #{card.name} (#{card.key_code}) - Cost:#{card.cost} HP:#{card.hp} ATK:#{card.attack}#{keywords_display}"
    end
    puts ""
    puts "Total: #{Card.count} cards"
  end
end

namespace :decks do
  desc "デッキ定義一覧を表示する"
  task list: :environment do
    require "yaml"

    decks_dir = Rails.root.join("db", "data", "decks")

    puts "=== Available Decks ==="
    Dir.glob(decks_dir.join("*.yml")).each do |file_path|
      deck_data = YAML.safe_load_file(file_path, permitted_classes: [ Symbol ])
      deck_key = File.basename(file_path, ".yml")
      puts "  [#{deck_key}] #{deck_data['name']} - #{deck_data['cards'].size}枚"
      puts "    #{deck_data['description']}"
    end
  end

  desc "デッキの整合性をチェックする（存在しないカードがないか確認）"
  task validate: :environment do
    require "yaml"

    decks_dir = Rails.root.join("db", "data", "decks")
    all_valid = true

    Dir.glob(decks_dir.join("*.yml")).each do |file_path|
      deck_data = YAML.safe_load_file(file_path, permitted_classes: [ Symbol ])
      deck_name = deck_data["name"]
      card_keys = deck_data["cards"]

      puts "Validating: #{deck_name}"

      missing_cards = card_keys - Card.where(key_code: card_keys).pluck(:key_code)

      if missing_cards.any?
        all_valid = false
        puts "  ! Missing cards: #{missing_cards.join(', ')}"
      else
        puts "  ✓ All #{card_keys.size} cards exist"
      end
    end

    puts ""
    if all_valid
      puts "=== All decks are valid ==="
    else
      puts "=== Some decks have missing cards. Run 'rake cards:import' first. ==="
    end
  end
end
