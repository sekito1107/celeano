require "rails_helper"

RSpec.describe GameChannel, type: :channel do
  let(:player) { create(:user) }
  let(:game) { create(:game) }
  let!(:game_player) { create(:game_player, game: game, user: player) }
  let(:other_user) { create(:user) }
  let(:other_game) { create(:game) }

  before do
    stub_connection current_user: player
  end

  describe "購読 (subscription)" do
    context "正しいパラメータと権限がある場合" do
      it "購読に成功し、ゲームのストリームが開始されること" do
        subscribe(game_id: game.id)
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(game)
      end
    end

    context "ゲームIDが無効な場合" do
      it "購読が拒否されること" do
        subscribe(game_id: 99999)
        expect(subscription).to be_rejected
      end
    end

    context "ユーザーがゲームの参加者ではない場合" do
      it "購読が拒否されること" do
        subscribe(game_id: other_game.id)
        expect(subscription).to be_rejected
      end
    end

    context "認証されていないユーザーの場合" do
      before do
        stub_connection current_user: nil
      end

      it "購読が拒否されること" do
        subscribe(game_id: game.id)
        expect(subscription).to be_rejected
      end
    end
  end
end
