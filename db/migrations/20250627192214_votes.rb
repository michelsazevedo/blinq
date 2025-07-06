# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:votes) do
      primary_key :id
      foreign_key :post_id, :posts, null: false, on_delete: :cascade

      Integer  :user_id,    null: false, index: true
      String   :vote_type,  null: false, index: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index %i[post_id user_id], unique: true
      check vote_type: %w[upvote downvote]
    end
  end
end
