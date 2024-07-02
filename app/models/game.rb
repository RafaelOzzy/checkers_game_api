class Game < ApplicationRecord
  has_many :pieces

  validates :status, inclusion: { in: %w(waiting_for_opponent player_1_turn player_2_turn player_1_won player_2_won) }
end
