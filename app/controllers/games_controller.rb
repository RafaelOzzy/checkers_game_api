class GamesController < ApplicationController
  before_action :set_game, only: [:join, :status, :pieces, :moves, :move]
  before_action :validate_token, only: [:status, :pieces, :moves, :move]

  def create
    @game = Game.new(status: 'waiting_for_opponent', game_token: SecureRandom.hex(10))
    if @game.save
      initialize_pieces(@game)
      render json: { game_id: @game.id, game_token: @game.game_token }, status: :created
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def join
    if @game.status == 'waiting_for_opponent'
      @game.update(status: 'player_1_turn')
      render json: { game_id: @game.id, game_token: @game.game_token }
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
    destination = params.require(:destination).permit(:row, :col).to_h.symbolize_keys

    if (@game.status == 'player_1_turn' && request.headers['Player'] != '1') || (@game.status == 'player_2_turn' && request.headers['Player'] != '2')
      render json: { error: 'Not your turn' }, status: :unprocessable_entity
      return
    end

    if valid_move?(piece, destination)
      is_capture = capture_move?(piece, destination)
      capture_piece(piece, destination) if is_capture
      piece.update(row: destination[:row], col: destination[:col])
      check_king(piece)
      if is_capture && can_continue_capture?(piece)
        render json: { success: true, piece: piece, continue_capture: true }
      else
        switch_turns
        render json: { success: true, piece: piece, continue_capture: false }
      end
    else
      render json: { error: 'Invalid move or capture required' }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def validate_token
    token = request.headers['Authorization']
    unless @game.game_token == token
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end

  def initialize_pieces(game)
    [0, 1, 2].each do |row|
      (0..7).each do |col|
        if (row + col).odd?
          Piece.create(game: game, player: 1, row: row, col: col, king: false)
        end
      end
    end

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
    capture_moves = possible_moves.select { |move| capture_move?(piece, move) }
    all_capture_moves = @game.pieces.where(player: piece.player).flat_map { |p| calculate_possible_moves(p).select { |move| capture_move?(p, move) } }

    if all_capture_moves.any?
      capture_moves.include?(destination)
    else
      possible_moves.include?(destination)
    end
  end

  def calculate_possible_moves(piece)
    moves = []
    capture_moves = []
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
        capture_moves << { row: capture_row, col: capture_col }
      end
    end

    capture_moves.any? ? capture_moves : moves
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
    captured_piece = @game.pieces.find_by(row: capture_row, col: capture_col)
    captured_piece.destroy if captured_piece
  end

  def can_continue_capture?(piece)
    calculate_possible_moves(piece).any? { |move| capture_move?(piece, move) }
  end

  def check_king(piece)
    if (piece.player == 1 && piece.row == 7) || (piece.player == 2 && piece.row == 0)
      piece.update(king: true)
    end
  end

  def switch_turns
    new_status = @game.status == 'player_1_turn' ? 'player_2_turn' : 'player_1_turn'
    @game.update(status: new_status)
  end
end
