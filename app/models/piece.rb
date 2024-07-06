class Piece < ApplicationRecord
  belongs_to :game

  validates :player, inclusion: { in: [1, 2] }
end
