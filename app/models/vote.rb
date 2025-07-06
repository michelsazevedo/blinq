# frozen_string_literal: true

# Vote Model
class Vote < Sequel::Model
  include ApplicationModel

  def validate
    super
    validates_presence %i[user_id vote_type post_id]
    validates_includes %w[upvote downvote], :vote_type
  end

  def upvote?
    vote_type == 'upvote'
  end

  def downvote?
    vote_type == 'downvote'
  end

  def safe_multi_insert(records)
    multi_insert(records)
  rescue Sequel::DatabaseError => e
    Sinatra.logger.warn("Multi Insert failed. Proceeding with fallback to per-record inserts.: #{e.message}")
    single_insert(records)
  end

  def single_insert(records)
    records.each do |record|
      insert(record)
    rescue Sequel::DatabaseError => e
      logger.error("Invalid vote: #{record.inspect} - #{e.message}")
    end
  end
end
