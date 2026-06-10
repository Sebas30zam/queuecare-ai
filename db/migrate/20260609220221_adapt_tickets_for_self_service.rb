class AdaptTicketsForSelfService < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tickets, :created_by_id, true

    add_column :tickets,
               :intake_source,
               :string,
               null: false,
               default: "assisted"

    add_column :tickets,
               :assistance_type,
               :string

    add_index :tickets, :intake_source
    add_index :tickets, :assistance_type
  end
end
