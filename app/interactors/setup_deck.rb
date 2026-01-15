# デッキ定義YAMLを読み込み、GameCardレコードを生成するInteractor
class SetupDeck
  include Interactor

  def call
    game = context.game

    game.game_players.each do |game_player|
      setup_deck_for_player(game_player)
    end
  end

  private

  def setup_deck_for_player(game_player)
    deck_type = game_player.deck_type || "cthulhu"
    deck_data = load_deck_definition(deck_type)

    context.fail!(message: "Deck definition not found: #{deck_type}") unless deck_data

    card_key_codes = deck_data["cards"]
    context.fail!(message: "No cards in deck definition") if card_key_codes.blank?

    cards_by_key_code = Card.where(key_code: card_key_codes).index_by(&:key_code)

    card_key_codes.each_with_index do |key_code, index|
      card = cards_by_key_code[key_code]
      unless card
        context.fail!(message: "Card not found: #{key_code} in deck #{deck_type}")
      end

      GameCard.create!(
        game: context.game,
        user: game_player.user,
        game_player: game_player,
        card: card,
        location: :deck,
        position_in_stack: index,
        current_hp: card.hp,
        current_attack: card.attack
      )
    end
  end

  def deck_cache
    @deck_cache ||= {}
  end

  def load_deck_definition(deck_type)
    return deck_cache[deck_type] if deck_cache.key?(deck_type)

    file_path = Rails.root.join("db", "data", "decks", "#{deck_type}_deck.yml")
    return nil unless File.exist?(file_path)

    deck_cache[deck_type] = YAML.safe_load_file(file_path, permitted_classes: [ Symbol ])
  end
end
