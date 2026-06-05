class CreateServiceWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :service_windows do |t|
      t.references :queue_service, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :service_windows, :code, unique: true
    add_index :service_windows, :active
  end
end
