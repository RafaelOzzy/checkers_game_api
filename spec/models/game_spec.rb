require 'rails_helper'

RSpec.describe Game, type: :model do
  it 'is valid with valid attributes' do
    game = Game.new(status: 'waiting_for_opponent', game_token: SecureRandom.hex(10))
    expect(game).to be_valid
  end

  it 'is not valid without a status' do
    game = Game.new(status: nil, game_token: SecureRandom.hex(10))
    expect(game).not_to be_valid
  end

  it 'is not valid without a game token' do
    game = Game.new(status: 'waiting_for_opponent', game_token: nil)
    expect(game).not_to be_valid
  end
end
