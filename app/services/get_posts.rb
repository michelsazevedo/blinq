# frozen_string_literal: true

class GetPosts
  attr_reader :limit

  def self.call(limit: 20)
    new(limit).call
  end

  def initialize(limit)
    @limit = limit
  end

  def call
    recent_posts_ids.filter_map.with_index do |post_id, index|
      post = recent_posts_cache[index]

      if post
        post.values
      else
        Sinatra.cache.fetch("post:#{post_id}") do
          Post.find(id: post_id)
        end.values
      end
    end
  end

  private

  def recent_posts_ids
    @recent_posts_ids ||= Sinatra.cache.fetch(cache_key) do
      Post.order(Sequel.desc(:updated_at)).limit(limit).map(&:id)
    end
  end

  def recent_posts_cache
    @recent_posts_cache ||= begin
      recent_posts_keys = recent_posts_ids.map { |id| "post:#{id}" }
      Sinatra.cache.fetch_multi(recent_posts_keys)
    end
  end

  def cache_key
    last_updated_at = Time.parse(Post.max(:updated_at).to_s)&.strftime('%Y%m%d%H%M%S') || 0
    "posts:recent_posts:#{last_updated_at}"
  end

  private_class_method :new
end
