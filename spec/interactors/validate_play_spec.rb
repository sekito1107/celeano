require 'rails_helper'

RSpec.describe ValidatePlay, type: :interactor do
  describe '.call' do
    let(:user) { create(:user) }
    let(:game) { create(:game, seed: 12345) }
    let(:turn) { create(:turn, game: game, status: :planning) }
    let(:game_player) { create(:game_player, user: user, game: game, san: 20) }

    let(:card) { create(:card, :unit, cost: "1") }
    let(:game_card) { create(:game_card, game: game, game_player: game_player, card: card, location: :hand) }

    let(:context_params) do
      {
        game: game,
        turn: turn,
        game_player: game_player,
        game_card: game_card,
        position: :center
      }
    end

    context '正常系: 全ての条件を満たす場合' do
      it '成功し、確定したコスト(paid_cost)がContextに格納される' do
        result = ValidatePlay.call(context_params)

        expect(result).to be_a_success
        expect(result.paid_cost).to be_a(Integer)
        expect(result.paid_cost).to eq(1)
      end
    end

    context '異常系: 配置位置が指定されていない場合' do
      it '失敗し、エラーメッセージを返す' do
        result = ValidatePlay.call(context_params.merge(position: nil))

        expect(result).to be_a_failure
        expect(result.message).to eq("ユニットカードの配置位置が指定されていません")
      end
    end

    context '異常系: フェーズが異なる場合' do
      before { turn.update!(status: :resolving) }

      it '失敗し、エラーメッセージを返す' do
        expect(Dice).not_to receive(:roll)
        result = ValidatePlay.call(context_params)

        expect(result).to be_a_failure
        expect(result.message).to include("フェーズではありません")
      end
    end

    context '異常系: 召喚制限に達している場合' do
      before do
        allow(turn).to receive(:summon_limit_reached?).with(user).and_return(true)
      end

      it '失敗し、エラーメッセージを返す' do
        result = ValidatePlay.call(context_params.merge(position: :center))

        expect(result).to be_a_failure
        expect(result.message).to include("召喚上限に達しています")
      end
    end

    context '異常系: スロットが既にボード上のカードで使用されている場合' do
      let!(:existing_card) do
        create(:game_card,
          game: game,
          game_player: game_player,
          card: create(:card, :unit),
          location: :board,
          position: :center
        )
      end

      it '失敗し、エラーメッセージを返す' do
        result = ValidatePlay.call(context_params.merge(position: :center))

        expect(result).to be_a_failure
        expect(result.message).to include("既に使用されています")
      end
    end

    context '異常系: スロットが予約中のカードで使用されている場合' do
      let!(:reserving_card) do
        create(:game_card,
          game: game,
          game_player: game_player,
          card: create(:card, :unit),
          location: :resolving,
          position: :left
        )
      end

      it '失敗し、エラーメッセージを返す' do
        result = ValidatePlay.call(context_params.merge(position: :left))

        expect(result).to be_a_failure
        expect(result.message).to include("既に使用されています")
      end
    end

    context '正常系: 別のスロットが使用されている場合は配置可能' do
      let!(:existing_card) do
        create(:game_card,
          game: game,
          game_player: game_player,
          card: create(:card, :unit),
          location: :board,
          position: :center
        )
      end

      it '成功する' do
        result = ValidatePlay.call(context_params.merge(position: :left))

        expect(result).to be_a_success
      end
    end
  end
end
