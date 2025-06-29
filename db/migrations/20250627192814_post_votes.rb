# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:posts) do
      add_column :upvotes,   Integer, default: 0, null: false
      add_column :downvotes, Integer, default: 0, null: false
    end
  end
end

