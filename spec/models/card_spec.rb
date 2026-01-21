require "rails_helper"

RSpec.describe Card, type: :model do
  describe "バリデーション" do
    it "名前があれば有効であること" do
      card = build(:card, name: "テストカード")
      expect(card).to be_valid
    end

    it "名前がない場合は無効であること" do
      card = build(:card, name: nil)
      expect(card).not_to be_valid
    end

    it "key_codeがあれば有効であること" do
      card = build(:card, key_code: "test_code")
      expect(card).to be_valid
    end

    it "key_codeがない場合は無効であること" do
      card = build(:card, key_code: nil)
      expect(card).not_to be_valid
    end

    it "重複するkey_codeは無効であること" do
      create(:card, key_code: "duplicate_code")
      card = build(:card, key_code: "duplicate_code")
      expect(card).not_to be_valid
    end
  end

  describe "ヘルパーメソッド" do
    let(:card) { create(:card) }
    let(:haste_keyword) { create(:keyword, name: "haste") }
    let(:guardian_keyword) { create(:keyword, name: "guardian") }

    describe "#has_keyword?" do
      context "アソシエーションがロードされていない場合" do
        it "キーワードを持っていればtrueを返すこと" do
          CardKeyword.create!(card: card, keyword: haste_keyword)
          expect(card.has_keyword?("haste")).to be true
        end

        it "キーワードを持っていなければfalseを返すこと" do
          expect(card.has_keyword?("haste")).to be false
        end
      end

      context "アソシエーションがロードされている場合" do
        it "キーワードを持っていればtrueを返すこと" do
          CardKeyword.create!(card: card, keyword: haste_keyword)
          card.keywords.load
          expect(card.has_keyword?("haste")).to be true
        end

        it "キーワードを持っていなければfalseを返すこと" do
          card.keywords.load
          expect(card.has_keyword?("haste")).to be false
        end
      end
    end

    describe "#haste?" do
      it "hasteキーワードを持っていればtrueを返すこと" do
        CardKeyword.create!(card: card, keyword: haste_keyword)
        expect(card.haste?).to be true
      end

      it "hasteキーワードを持っていなければfalseを返すこと" do
        expect(card.haste?).to be false
      end
    end

    describe "#guardian?" do
      it "guardianキーワードを持っていればtrueを返すこと" do
        CardKeyword.create!(card: card, keyword: guardian_keyword)
        expect(card.guardian?).to be true
      end

      it "guardianキーワードを持っていなければfalseを返すこと" do
        expect(card.guardian?).to be false
      end
    end
  end

  describe "#targeted?" do
    it "説明文に'対象'が含まれていればtrueを返すこと" do
      card = build(:card, description: "敵1体を対象とする")
      expect(card.targeted?).to be true
    end

    it "説明文に'対象'が含まれていなければfalseを返すこと" do
      card = build(:card, description: "全体にダメージ")
      expect(card.targeted?).to be false
    end

    it "説明文がnilの場合はfalseを返すこと" do
      card = build(:card, description: nil)
      expect(card.targeted?).to be false
    end
  end

  describe "#target_type" do
    context "ユニットの場合" do
      it "'slot'を返すこと" do
        card = build(:card, :unit)
        expect(card.target_type).to eq "slot"
      end
    end

    context "スペルの場合" do
      it "説明文に'対象'と'味方'が含まれる場合は'ally_unit'を返すこと" do
        card = build(:card, :spell, description: "味方のユニット1体を対象とする")
        expect(card.target_type).to eq "ally_unit"
      end

      it "説明文に'対象'と'敵'が含まれる場合は'enemy_unit'を返すこと" do
        card = build(:card, :spell, description: "敵のユニット1体を対象とする")
        expect(card.target_type).to eq "enemy_unit"
      end

      it "説明文に'対象'のみが含まれる場合は'any_unit'を返すこと" do
        card = build(:card, :spell, description: "ユニット1体を対象とする")
        expect(card.target_type).to eq "any_unit"
      end

      it "説明文に'敵の全ユニット'が含まれる場合は'enemy_board'を返すこと" do
        card = build(:card, :spell, description: "敵の全ユニットにダメージ")
        expect(card.target_type).to eq "enemy_board"
      end

      it "説明文に'自分の全ユニット'が含まれる場合は'ally_board'を返すこと" do
        card = build(:card, :spell, description: "自分の全ユニットを回復")
        expect(card.target_type).to eq "ally_board"
      end

      it "それ以外の場合は'none'を返すこと" do
        card = build(:card, :spell, description: "ランダムな効果")
        expect(card.target_type).to eq "none"
      end
    end
  end

  describe "#resolved_image_path" do
    it "image_nameが存在する場合はそれを使用してパスを解決すること" do
      card = build(:card, image_name: "custom_art.png")
      # アセットパスの解決は環境依存するため、終わりの部分だけチェックするか、あるいはモックする
      # ここでは単純にエラーにならないことと、文字列が返ることを確認
      expect(card.resolved_image_path).to include("custom_art.png")
    end

    context "image_nameが存在しない場合" do
      it "スペルの場合は'art_ritual'を含むパスを返すこと" do
        card = build(:card, :spell, name: "不思議な呪文", image_name: nil)
        expect(card.resolved_image_path).to include("art_ritual")
      end

      it "名前に'ダゴン'が含まれる場合は'art_dagon'を含むパスを返すこと" do
        card = build(:card, :unit, name: "ダゴンの落とし子", image_name: nil)
        expect(card.resolved_image_path).to include("art_dagon")
      end

      it "名前に'信者'が含まれる場合は'art_cultist'を含むパスを返すこと" do
        card = build(:card, :unit, name: "狂信者", image_name: nil)
        expect(card.resolved_image_path).to include("art_cultist")
      end

      it "名前に'ショゴス'が含まれる場合は'art_shoggoth'を含むパスを返すこと" do
        card = build(:card, :unit, name: "ショゴス", image_name: nil)
        expect(card.resolved_image_path).to include("art_shoggoth")
      end

      it "該当しない場合は'art_cultist'を含むパスを返すこと" do
        card = build(:card, :unit, name: "謎の生物", image_name: nil)
        expect(card.resolved_image_path).to include("art_cultist")
      end
    end
  end
end
