class AddSurveyTokenToTickets < ActiveRecord::Migration[8.1]
  class MigrationTicket < ActiveRecord::Base
    self.table_name = "tickets"
  end

  def up
    add_column :tickets, :survey_token, :string
    add_index :tickets, :survey_token, unique: true

    MigrationTicket.reset_column_information

    MigrationTicket.find_each do |ticket|
      ticket.update_columns(survey_token: SecureRandom.base58(24))
    end

    change_column_null :tickets, :survey_token, false
  end

  def down
    remove_index :tickets, :survey_token
    remove_column :tickets, :survey_token
  end
end
