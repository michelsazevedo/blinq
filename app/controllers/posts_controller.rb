# frozen_string_literal: true

# Posts
class PostsController < ApplicationController
  get '/' do
    posts = GetPosts.call
    render json: Oj.dump({ data: posts, error: nil }), status: 200
  end

  post '/' do
    CreatePost.call(post_params) do |service|
      service.success do |post|
        render json: Oj.dump({ data: post, error: nil }), status: 200
      end

      service.failure do |errors|
        render json: Oj.dump({ data: nil, errors: errors }), status: 422
      end
    end
  end

  post '/:id/vote' do
    CreateVote.call(vote_params) do |service|
      service.success do |vote|
        render json: Oj.dump({ data: vote, error: nil }), status: 200
      end

      service.failure do |errors|
        render json: Oj.dump({ data: nil, errors: errors }), status: 422
      end
    end
  end

  private

  # @return [Hash]
  def post_params
    request_params.slice(:title, :content, :user_id)
  end

  def vote_params
    request_params.slice(:vote_type, :user_id).merge(post_id: params[:id])
  end
end
