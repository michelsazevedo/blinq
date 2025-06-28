# frozen_string_literal: true

# Posts
class PostsController < ApplicationController
  post '/' do
    CreatePost.call(post_params) do |service|
      service.success do |post|
        render json: { data: post.to_json, error: nil }.to_json, status: 200
      end

      service.failure do |errors|
        render json: { data: nil, errors: errors }.to_json, status: 422
      end
    end
  end

  private

  # @return [Hash]
  def post_params
    request_params.slice(:title, :content, :user_id)
  end
end
