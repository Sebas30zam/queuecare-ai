class CreateDailySequences < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_sequences do |t|
      t.references :queue_service, null: false, foreign_key: true
      t.date :sequence_date, null: false
      t.integer :current_number, null: false, default: 0

      t.timestamps
    end

    add_index :daily_sequences,
              [ :queue_service_id, :sequence_date ],
              unique: true
  end
end
