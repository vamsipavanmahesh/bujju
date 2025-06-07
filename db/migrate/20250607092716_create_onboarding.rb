class CreateOnboarding < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :notification_time_setting

      t.timestamps
    end
  end
end
