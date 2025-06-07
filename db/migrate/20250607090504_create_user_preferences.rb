class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.time :notification_time
      t.string :timezone, limit: 50
      t.timestamps
    end
  end
end
