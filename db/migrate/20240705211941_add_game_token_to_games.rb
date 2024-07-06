class AddGameTokenToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :game_token, :string
  end
end
