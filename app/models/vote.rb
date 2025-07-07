# frozen_string_literal: true

# Vote Model
class Vote < Sequel::Model
  include ApplicationModel

  many_to_one :post

  class << self
    def safe_multi_insert(records)
      multi_insert(records)

      counter_cache(records)
    rescue Sequel::DatabaseError => e
      Sinatra.logger.warn("Multi Insert failed. Proceeding with fallback to per-record inserts.: #{e.message}")
      single_insert(records)
    end

    def single_insert(records)
      records.each do |record|
        insert(record)
      rescue Sequel::DatabaseError => e
        logger.error("Invalid vote: #{record.inspect}: #{e.message}")
      end

      counter_cache(records)
    end

    def counter_cache(records)
      votes = records.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |vote, hash|
        type    = vote[:vote_type] == 'upvote' ? 'upvotes' : 'downvotes'
        post_id = vote[:post_id]

        hash[post_id][type] += 1
      end
      Post.update_vote_counters(votes)
    end
  end

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
end
