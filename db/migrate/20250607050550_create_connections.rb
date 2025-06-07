class CreateConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :connections do |t|
      t.string :name, null: false
      t.string :phone_number, null: false
      t.string :relationship, null: false, default: 'friend'
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
