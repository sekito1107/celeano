require "rails_helper"

RSpec.describe Move, type: :model do
  describe "アソシエーション" do
    it "turnに属していること" do
      expect(Move.reflect_on_association(:turn).macro).to eq :belongs_to
    end
    it "userに属していること" do
      expect(Move.reflect_on_association(:user).macro).to eq :belongs_to
    end
    it "game_cardに属していること" do
      expect(Move.reflect_on_association(:game_card).macro).to eq :belongs_to
    end
    it "target_game_cardに属していること" do
      assoc = Move.reflect_on_association(:target_game_card)
      expect(assoc.macro).to eq :belongs_to
      expect(assoc.options[:class_name]).to eq "GameCard"
      expect(assoc.options[:optional]).to eq true
    end
    it "target_playerに属していること" do
      assoc = Move.reflect_on_association(:target_player)
      expect(assoc.macro).to eq :belongs_to
      expect(assoc.options[:class_name]).to eq "GamePlayer"
      expect(assoc.options[:optional]).to eq true
    end
  end

  describe "Enum" do
    it "action_typeが定義されていること" do
      expect(Move.defined_enums["action_type"]).to eq({ "play" => 0, "attack" => 1, "spell" => 2 })
    end
    it "positionが定義されていること" do
      expect(Move.defined_enums["position"]).to eq({ "left" => 0, "center" => 1, "right" => 2 })
      expect(Move.new).not_to respond_to(:left_position?) # prefix check: prefix is false so no prefix
      expect(Move.new).to respond_to(:left?)
    end
  end

  describe "バリデーション" do
    context "Playアクションの場合" do
      subject { build(:move, action_type: :play, position: :center) }

      it "positionがあれば有効であること" do
        expect(subject).to be_valid
      end

      it "positionがないと無効であること" do
        subject.position = nil
        expect(subject).not_to be_valid
      end
    end

    context "Spellアクションの場合" do
      subject { build(:move, action_type: :spell, position: nil) }

      it "positionがなければ有効であること" do
        expect(subject).to be_valid
      end

      it "positionがあると無効であること" do
        subject.position = :center
        expect(subject).not_to be_valid
      end
    end

    context "Attackアクションの場合" do
      subject { build(:move, action_type: :attack, position: nil) }

      it "positionがなければ有効であること" do
        expect(subject).to be_valid
      end

      it "positionがあると無効であること" do
        subject.position = :center
        expect(subject).not_to be_valid
      end
    end
  end
end
