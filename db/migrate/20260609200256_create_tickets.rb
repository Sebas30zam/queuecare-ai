class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :queue_service,
                   null: false,
                   foreign_key: true

      t.references :service_window,
                   null: true,
                   foreign_key: true

      t.references :created_by,
                   null: false,
                   foreign_key: { to_table: :users }

      t.references :assigned_agent,
                   null: true,
                   foreign_key: { to_table: :users }

      t.string :ticket_number, null: false
      t.date :sequence_date, null: false
      t.integer :daily_sequence, null: false

      t.string :customer_name
      t.string :customer_identifier
      t.text :request_description

      t.string :priority, null: false
      t.integer :priority_weight, null: false
      t.string :status, null: false

      t.datetime :called_at
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :cancelled_at
      t.datetime :no_show_at

      t.timestamps
    end

    add_index :tickets,
              [ :ticket_number, :sequence_date ],
              unique: true

    add_index :tickets, :status
    add_index :tickets, :priority
  end
end
