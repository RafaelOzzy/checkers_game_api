class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :status
      t.string :player1_token
      t.string :player2_token

      t.timestamps
    end
  end
end
