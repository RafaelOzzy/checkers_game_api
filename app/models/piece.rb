class Piece < ApplicationRecord
  belongs_to :game

  validates :player, inclusion: { in: [1, 2] }

  validates :row, presence: true
  validates :col, presence: true
  validates :player, presence: true
end
