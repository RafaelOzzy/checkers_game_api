FactoryBot.define do
  factory :game do
    status { 'waiting_for_opponent' }
    game_token { SecureRandom.hex(10) }
  end
end
