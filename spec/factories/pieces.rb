FactoryBot.define do
  factory :piece do
    association :game
    player { 1 }
    row { 0 }
    col { 1 }
    king { false }
  end
end
