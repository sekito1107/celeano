# scripts/setup_demo_game.rb

# 1. Find Users
user1 = User.find_by(email_address: "test1@example.com")
user2 = User.find_by(email_address: "test2@example.com")

unless user1 && user2
  puts "Error: Test users not found. Run bin/rails db:seed first."
  exit 1
end

puts "Found Users: #{user1.name} (Player), #{user2.name} (Opponent)"

# 2. Cleanup old active games for these users to avoid confusion
game_ids = Game.where(status: [ :matching, :playing ])
               .joins(:game_players)
               .where(game_players: { user_id: [ user1.id, user2.id ] })
               .distinct
               .pluck(:id)

Game.where(id: game_ids).destroy_all

# 3. Create Game
game = Game.create!(status: :playing)
puts "Created Game ID: #{game.id}"

# 4. Create Players
p1 = GamePlayer.create!(game: game, user: user1, role: :host, hp: 20, san: 20)
p2 = GamePlayer.create!(game: game, user: user2, role: :guest, hp: 18, san: 15) # p2 slightly damaged

puts "Created Players"

# 5. Populate Cards
# Fetch some card definitions from DB
cards = Card.all.to_a
if cards.empty?
  puts "Error: No cards found in DB."
  exit 1
end

def add_cards(player, cards, location, count, position: nil)
  count.times do |i|
    # For board, only pick unit cards
    candidate_cards = (location == :board) ? cards.select { |c| c.card_type == "unit" } : cards

    # Fallback if no units found (unlikely)
    candidate_cards = cards if candidate_cards.empty?

    card_def = candidate_cards.sample
    GameCard.create!(
      game: player.game,
      user: player.user,
      game_player: player,
      card: card_def,
      location: location,
      position_in_stack: (location == :hand || location == :deck) ? i : nil,
      position: position
    )
    # Apply some status for visual check
    # TODO: Apply status modifiers (stun, etc.) for visual testing once supported
  end
end

puts "Populating decks and hands..."

# Player 1
add_cards(p1, cards, :hand, 5)
add_cards(p1, cards, :deck, 10)
add_cards(p1, cards, :board, 1, position: :center) # 1 monster on field
add_cards(p1, cards, :graveyard, 2)
add_cards(p1, cards, :banished, 1)

# Player 2 (Opponent)
add_cards(p2, cards, :hand, 4) # Opponent hand hidden usually but distinct count
add_cards(p2, cards, :deck, 12)
add_cards(p2, cards, :board, 2, position: :left)
add_cards(p2, cards, :board, 1, position: :right)
add_cards(p2, cards, :banished, 1)

puts "Game Setup Complete!"
puts "---------------------------------------------------"
puts "Access URL: http://localhost:3000/games/#{game.id}"
puts "Login as:   #{user1.email_address} / testpass123"
puts "---------------------------------------------------"
