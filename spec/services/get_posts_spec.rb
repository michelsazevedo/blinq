# frozen_string_literal: true

require 'spec_helper'
require 'debug'

RSpec.describe GetPosts, type: :service do
  subject(:service) { described_class }
  let(:cache) { instance_double(Cache).as_null_object }
  let(:posts) { create_list(:post, 3) }
  let(:post_ids) { posts.map(&:id) }
  let(:last_updated_at) { Time.parse(posts.last.updated_at.to_s).strftime('%Y%m%d%H%M%S') }
  let(:cached_posts) { Hash[(0...posts.count).zip(posts)] }

  before do
    allow(Sinatra).to receive(:cache).and_return(cache)
    allow(cache).to receive(:fetch).with("posts:recent_posts:#{last_updated_at}").and_return(post_ids)
    allow(cache).to receive(:fetch_multi).and_return(cached_posts)

    Cache.configure
    Cache.instance.flushall
  end

  it 'returns a list of posts' do
    posts = service.call

    expect(posts.size).to eq(3)
    expect(posts).to all(include(:id, :title, :content, :user_id))
  end
end
