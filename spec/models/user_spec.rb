require 'rails_helper'

RSpec.describe User, type: :model do
  # ensure_not_playing_active_gameで自分でバリデーションコールバックを作成しているためテストを書く
  describe 'バリデーション' do
    it '名前が必須であること' do
      user = User.new(name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end
  end

  describe '削除時の挙動' do
    let!(:user) { create(:user) } # let!にして事前に作成

    context 'アクティブなゲームに参加していない場合' do
      it '削除できること' do
        expect {
          user.destroy
        }.to change(User, :count).by(-1)
      end
    end

    context '終了したゲームに参加している場合' do
      let(:game) { create(:game, status: :finished) }
      let!(:game_player) { create(:game_player, user: user, game: game) }

      it '削除できること' do
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end

    context 'マッチング中のゲームに参加している場合' do
      let(:game) { create(:game, status: :matching) }
      let!(:game_player) { create(:game_player, user: user, game: game) }

      it '削除できず、エラーが追加されること' do
        expect { user.destroy }.not_to change(User, :count)
        expect(user.errors[:base]).to include("アクティブなゲームに参加中のユーザーは削除できません")
      end
    end

    context 'プレイ中のゲームに参加している場合' do
      let(:game) { create(:game, status: :playing) }
      let!(:game_player) { create(:game_player, user: user, game: game) }

      it '削除できず、エラーが追加されること' do
        expect { user.destroy }.not_to change(User, :count)
        expect(user.errors[:base]).to include("アクティブなゲームに参加中のユーザーは削除できません")
      end
    end
  end
end
