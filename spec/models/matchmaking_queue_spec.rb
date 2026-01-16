require 'rails_helper'

RSpec.describe MatchmakingQueue, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:subject) { build(:matchmaking_queue, user: user, deck_type: 'cthulhu') }

    it '有効な属性値の場合は有効であること' do
      expect(subject).to be_valid
    end

    it 'ユーザーがいない場合は無効であること' do
      subject.user = nil
      expect(subject).to be_invalid
    end

    it 'ユーザーIDが重複している場合は無効であること' do
      create(:matchmaking_queue, user: user)
      expect(subject).to be_invalid
    end

    it 'デッキタイプがない場合は無効であること' do
      subject.deck_type = nil
      expect(subject).to be_invalid
    end
  end
end
