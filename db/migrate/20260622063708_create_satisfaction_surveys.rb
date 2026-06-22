class CreateSatisfactionSurveys < ActiveRecord::Migration[8.1]
  def change
    create_table :satisfaction_surveys do |t|
      t.references :ticket,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.integer :rating, null: false
      t.text :comment
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
