class PlayCard
  include Interactor::Organizer

  organize ValidatePlay, PayCost, CreateMove, ProcessCardMovement, TriggerPlayEffect

  around do |organizer_block|
    ActiveRecord::Base.transaction do
      organizer_block.call
    end
  end
end
