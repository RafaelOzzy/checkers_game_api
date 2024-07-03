class GamesController < ApplicationController
  before_action :set_game, only: [:show, :join, :status, :pieces, :moves, :move]
  before_action :validate_token, only: [:status, :pieces, :moves, :move]

  def create
    @game = Game.new(status: 'waiting_for_opponent', player1_token: SecureRandom.hex(10))
    if @game.save
      initialize_pieces(@game)
      render json: { game_id: @game.id, player1_token: @game.player1_token }, status: :created
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def join
    if @game.status == 'waiting_for_opponent'
      @game.update(player2_token: SecureRandom.hex(10), status: 'player_1_turn')
      render json: { game_id: @game.id, player2_token: @game.player2_token }
    else
      render json: { error: 'Game is not available to join' }, status: :unprocessable_entity
    end
  end

  def status
    render json: { status: @game.status }
  end

  def pieces
    render json: @game.pieces
  end

  def moves
    piece = @game.pieces.find(params[:piece_id])
    moves = calculate_possible_moves(piece)
    render json: { moves: moves }
  end

  def move
    piece = @game.pieces.find(params[:piece_id])
    destination = params[:destination] # Expected format: { row: x, col: y }
    if valid_move?(piece, destination)
      piece.update(row: destination[:row], col: destination[:col])
      capture_piece(piece, destination) if capture_move?(piece, destination)
      check_king(piece)
      switch_turns
      render json: { success: true, piece: piece }
    else
      render json: { error: 'Invalid move' }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def validate_token
    token = request.headers['Authorization']
    unless [@game.player1_token, @game.player2_token].include?(token)
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end

  def initialize_pieces(game)
     # Player 1's pieces (rows 0, 1, 2)
     [0, 1, 2].each do |row|
      (0..7).each do |col|
        if (row + col).odd?
          Piece.create(game: game, player: 1, row: row, col: col, king: false)
        end
      end
    end

    # Player 2's pieces (rows 5, 6, 7)
    [5, 6, 7].each do |row|
      (0..7).each do |col|
        if (row + col).odd?
          Piece.create(game: game, player: 2, row: row, col: col, king: false)
        end
      end
    end
  end

  def valid_move?(piece, destination)
    possible_moves = calculate_possible_moves(piece)
    possible_moves.include?(destination)
  end

  def calculate_possible_moves(piece)
    moves = []
    directions = piece.king ? [[1, 1], [1, -1], [-1, 1], [-1, -1]] : piece.player == 1 ? [[1, 1], [1, -1]] : [[-1, 1], [-1, -1]]
    directions.each do |direction|
      new_row = piece.row + direction[0]
      new_col = piece.col + direction[1]
      if valid_position?(new_row, new_col) && empty_square?(new_row, new_col)
        moves << { row: new_row, col: new_col }
      end
      capture_row = piece.row + 2 * direction[0]
      capture_col = piece.col + 2 * direction[1]
      if valid_position?(capture_row, capture_col) && empty_square?(capture_row, capture_col) && enemy_piece?(piece, new_row, new_col)
        moves << { row: capture_row, col: capture_col }
      end
    end
    moves
  end

  def valid_position?(row, col)
    row.between?(0, 7) && col.between?(0, 7)
  end

  def empty_square?(row, col)
    @game.pieces.where(row: row, col: col).empty?
  end

  def enemy_piece?(piece, row, col)
    other_piece = @game.pieces.find_by(row: row, col: col)
    other_piece && other_piece.player != piece.player
  end

  def capture_move?(piece, destination)
    (piece.row - destination[:row]).abs == 2
  end

  def capture_piece(piece, destination)
    capture_row = (piece.row + destination[:row]) / 2
    capture_col = (piece.col + destination[:col]) / 2
    @game.pieces.find_by(row: capture_row, col: capture_col).destroy
  end

  def check_king(piece)
    if (piece.player == 1 && piece.row == 7) || (piece.player == 2 && piece.row == 0)
      piece.update(king: true)
    end
  end

  def switch_turns
    @game.update(status: @game.status == 'player_1_turn' ? 'player_2_turn' : 'player_1_turn')
  end
end
