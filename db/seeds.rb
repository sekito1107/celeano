# キーワードマスターデータ
puts "Creating keywords..."
keywords_data = {
  "haste" => "召喚酔いなしで攻撃可能",
  "guardian" => "他のユニットへの攻撃を引きつける"
}

ActiveRecord::Base.transaction do
  keywords_data.each do |name, description|
    keyword = Keyword.find_or_initialize_by(name: name)
    keyword.description = description
    keyword.save!
  end
end

puts "Created #{Keyword.count} keywords"

# カードデータの読み込み
puts "Loading cards..."

card_files = Dir[Rails.root.join("db/data/cards/*.yml")]

ActiveRecord::Base.transaction do
  card_files.each do |file|
    puts "  Loading #{File.basename(file)}..."
    cards_data = YAML.safe_load_file(file)

    cards_data.each do |key_code, attrs|
      card = Card.find_or_initialize_by(key_code: key_code)
      card.assign_attributes(
        name: attrs["name"],
        card_type: attrs["card_type"],
        cost: attrs["cost"].to_s,
        attack: attrs["attack"].to_s,
        hp: attrs["hp"].to_i,
        threshold_san: attrs["threshold"].to_i, # YAMLのthresholdをthreshold_sanとして保存
        description: attrs["description"],
        description_insane: attrs["description_insane"],
        flavor_text: attrs["flavor_text"],
        image_name: attrs["image_name"]
      )
      card.save!

      # キーワードの関連付け
      keyword_names = attrs["keywords"] || []
      keyword_ids = Keyword.where(name: keyword_names).pluck(:id)
      existing_ids = card.card_keywords.pluck(:keyword_id)

      # 不要な関連を削除
      card.card_keywords.where.not(keyword_id: keyword_ids).destroy_all

      # 新規関連を追加
      (keyword_ids - existing_ids).each do |keyword_id|
        CardKeyword.create!(card: card, keyword_id: keyword_id)
      end
    end
  end
end

puts "Created #{Card.count} cards"
puts "Created #{CardKeyword.count} card-keyword associations"

# ===========================================
# テストユーザーの作成（開発環境用）
# ===========================================
if Rails.env.development? || Rails.env.test?
  puts "Creating test users..."

  test_users = [
    { name: "Admin", email_address: "admin@example.com", password: "adminpass123" },
    { name: "TestUser1", email_address: "test1@example.com", password: "testpass123" },
    { name: "TestUser2", email_address: "test2@example.com", password: "testpass123" }
  ]

  ActiveRecord::Base.transaction do
    test_users.each do |attrs|
      user = User.find_or_initialize_by(email_address: attrs[:email_address])
      user.name = attrs[:name]
      user.password = attrs[:password]
      user.save!
    end
  end

  puts "Created #{User.count} users"
end
