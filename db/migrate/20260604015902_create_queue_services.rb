class CreateQueueServices < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_services do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :estimated_attention_minutes

      t.timestamps
    end

    add_index :queue_services, :code, unique: true
    add_index :queue_services, :active
  end
end
