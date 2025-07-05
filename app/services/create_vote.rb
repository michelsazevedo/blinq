# frozen_string_literal: true

# Create Vote
class CreateVote
  include Result

  attributes :vote_type, :post_id, :user_id

  def call
    if post
      Cache.instance.increment("post:#{post_id}:#{vote_type}")

      upvotes = Cache.instance.get("post:#{post_id}:upvotes")
      downvotes = Cache.instance.get("post:#{post_id}:downvotes")

      publish('vote', vote_type: vote_type, post_id: post_id, user_id: user_id)
      Success({ post_id: post_id, upvotes: upvotes, downvotes: downvotes })
    else
      Failure('Post not found')
    end
  end

  private

  def post
    Cache.fetch("post:#{post_id}") do
      Post.find(id: post_id)
    end
  end
end
