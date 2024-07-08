require 'rails_helper'

RSpec.describe Piece, type: :model do
  let(:game) { Game.create(status: 'waiting_for_opponent', game_token: SecureRandom.hex(10)) }

  it 'is valid with valid attributes' do
    piece = Piece.new(game: game, player: 1, row: 0, col: 1, king: false)
    expect(piece).to be_valid
  end

  it 'is not valid without a game' do
    piece = Piece.new(game: nil, player: 1, row: 0, col: 1, king: false)
    expect(piece).not_to be_valid
  end

  it 'is not valid without a player' do
    piece = Piece.new(game: game, player: nil, row: 0, col: 1, king: false)
    expect(piece).not_to be_valid
  end

  it 'is not valid without a row' do
    piece = Piece.new(game: game, player: 1, row: nil, col: 1, king: false)
    expect(piece).not_to be_valid
  end

  it 'is not valid without a col' do
    piece = Piece.new(game: game, player: 1, row: 0, col: nil, king: false)
    expect(piece).not_to be_valid
  end
end
