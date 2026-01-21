require "rails_helper"

RSpec.describe BattleLog, type: :model do
  describe "アソシエーション" do
    it "turnに属していること" do
      expect(BattleLog.reflect_on_association(:turn).macro).to eq :belongs_to
    end
    it "gameを持つこと" do
      assoc = BattleLog.reflect_on_association(:game)
      expect(assoc.macro).to eq :has_one
      expect(assoc.options[:through]).to eq :turn
    end
  end

  describe "バリデーション" do
    it "event_typeがあれば有効であること" do
      log = build(:battle_log, event_type: "attack")
      expect(log).to be_valid
    end

    it "event_typeがない場合は無効であること" do
      log = build(:battle_log, event_type: nil)
      expect(log).not_to be_valid
    end
  end
end
