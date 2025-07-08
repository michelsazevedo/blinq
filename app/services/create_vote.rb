# frozen_string_literal: true

# Create Vote
class CreateVote
  include Result

  ALLOWED_TYPES = %w[upvote downvote].freeze
  REQUIRED_KEYS = %i[user_id post_id vote_type].freeze

  attributes :vote_type, :post_id, :user_id

  def call
    if post && valid?(vote)
      Sinatra.cache.increment("post:#{post_id}:#{vote_type}")
      upvotes, downvotes = Sinatra.cache.fetch_multi(["post:#{post_id}:upvotes", "post:#{post_id}:downvotes"])

      Sinatra.queue.publish('votes', vote)

      Success({ post_id: post_id, upvotes: (upvotes.to_i + post.upvotes),
                downvotes: (downvotes.to_i + post.downvotes) })
    else
      Failure('Vote not valid')
    end
  end

  private

  def vote
    @vote ||= { vote_type: vote_type, post_id: post_id, user_id: user_id }
  end

  def valid?(vote)
    return false unless vote.is_a?(Hash) && REQUIRED_KEYS.all? { |key| vote.key?(key) }

    ALLOWED_TYPES.include?(data[:vote_type])
  end

  def post
    Sinatra.cache.fetch("post:#{post_id}") do
      Post.find(id: post_id)
    end
  end
end
