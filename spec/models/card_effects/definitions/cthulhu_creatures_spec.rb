require 'rails_helper'

RSpec.describe CardEffects::Definitions::CthulhuCreatures do
  before do
    CardEffects::Registry.reset!
  end

  describe "Registry Registration" do
    it "star_spawnがEffectDefinitionとして登録されていること" do
      effect = CardEffects::Registry.find("star_spawn")
      expect(effect).to be_a(CardEffects::EffectDefinition)
    end

    it "ghoulが登録されていること" do
      effect = CardEffects::Registry.find("ghoul")
      expect(effect).to be_present
    end

    it "存在しないkey_codeはnilを返すこと" do
      effect = CardEffects::Registry.find("shoggoth")
      expect(effect).to be_nil
    end
  end
end
