module Api
  class DecksController < ApplicationController
    # GET /api/decks
    # 利用可能なデッキ一覧を返す
    def index
      decks = load_available_decks
      render json: decks
    end

    private

    def load_available_decks
      deck_files = Dir.glob(Rails.root.join("db", "data", "decks", "*.yml"))

      deck_files.map do |file_path|
        data = YAML.safe_load_file(file_path, permitted_classes: [ Symbol ])
        key = File.basename(file_path, "_deck.yml")

        {
          key: key,
          name: data["name"],
          description: data["description"]
        }
      end
    end
  end
end
