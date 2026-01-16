class MatchmakingChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # 切断時にマッチング離脱
    current_user.leave_matchmaking!
  end
end
