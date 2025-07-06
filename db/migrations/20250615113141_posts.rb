# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:posts) do
      primary_key :id

      String   :title,      null: false, size: 155
      String   :content,    null: false, text: true
      Integer  :user_id,    null: false, index: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
