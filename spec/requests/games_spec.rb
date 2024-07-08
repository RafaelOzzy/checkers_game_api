require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:game) { Game.create(status: 'waiting_for_opponent', game_token: SecureRandom.hex(10)) }
  let(:piece) { Piece.create(game: game, player: 1, row: 0, col: 1, king: false) }

  describe "POST /create" do
    it "creates a new game" do
      post "/games"
      expect(response).to have_http_status(:created)
    end
  end

  describe "POST /join" do
    it "allows a player to join a game" do
      post "/games/#{game.id}/join", headers: { Authorization: game.game_token }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /status" do
    it "returns the game status" do
      get "/games/#{game.id}/status", headers: { Authorization: game.game_token }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("status")
    end
  end

  describe "POST /move" do
    it "moves a piece" do
      game.update(status: 'player_1_turn')
      destination = { row: 1, col: 2 }
      post "/games/#{game.id}/move", params: { piece_id: piece.id, destination: destination }, headers: { Authorization: game.game_token, Player: '1' }
      expect(response).to have_http_status(:ok)
    end
  end
end
