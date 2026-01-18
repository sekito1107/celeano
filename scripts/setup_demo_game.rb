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

# 4.5 Create First Turn
Turn.create!(game: game, turn_number: 1, status: :planning)
puts "Created First Turn"

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
      position_in_stack: (location == :hand || location == :deck) ? (i + (position || 0)) : nil,
      position: position
    )
    # Apply some status for visual check
    # TODO: Apply status modifiers (stun, etc.) for visual testing once supported
  end
end

puts "Populating decks and hands..."

# Player 1
# Ensure at least 1 Unit and 1 Spell in hand
unit_card = cards.find { |c| c.card_type == "unit" }
# Ensure distinct spell types for testing
targeted_spell = cards.find { |c| c.key_code == "carcosa_vision" }  # Poison target
aoe_spell = cards.find { |c| c.key_code == "tidal_wave" }           # 2 dmg to all enemies (non-targeted)

# Fallback just in case seeds changed
unless targeted_spell
  puts "Warning: 'carcosa_vision' not found. Trying 'yellow_sign'..."
  targeted_spell = cards.find { |c| c.key_code == "yellow_sign" }
end

unless aoe_spell
  puts "Warning: 'tidal_wave' not found. Trying 'kings_presence'..."
  aoe_spell = cards.find { |c| c.key_code == "kings_presence" }
end

puts "Warning: Unit card not found!" unless unit_card
puts "Warning: Targeted spell not found (even fallback)!" unless targeted_spell
puts "Warning: AoE spell not found (even fallback)!" unless aoe_spell

if unit_card
  GameCard.create!(
      game: p1.game,
      user: p1.user,
      game_player: p1,
      card: unit_card,
      location: :hand,
      position_in_stack: 0
  )
end

if targeted_spell
  GameCard.create!(
      game: p1.game,
      user: p1.user,
      game_player: p1,
      card: targeted_spell,
      location: :hand,
      position_in_stack: 1
  )
end

if aoe_spell
  GameCard.create!(
      game: p1.game,
      user: p1.user,
      game_player: p1,
      card: aoe_spell,
      location: :hand,
      position_in_stack: 2
  )
end

add_cards(p1, cards, :hand, 3, position: 3) # Add 3 more random cards
add_cards(p1, cards, :deck, 10, position: 0)
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
