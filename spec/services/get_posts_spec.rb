# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetPosts, type: :service do
  subject(:service) { described_class }

  before do
    create_list(:post, 3)

    Cache.configure
    Cache.instance.flushall
  end

  it 'returns a list of posts' do
    posts = service.call

    expect(posts.size).to eq(3)
    expect(posts).to all(include(:id, :title, :content, :user_id))
  end
end
