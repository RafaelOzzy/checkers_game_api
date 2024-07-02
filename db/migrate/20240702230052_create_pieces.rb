class CreatePieces < ActiveRecord::Migration[7.1]
  def change
    create_table :pieces do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :player
      t.integer :row
      t.integer :col
      t.boolean :king

      t.timestamps
    end
  end
end
