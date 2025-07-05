# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bufferz do
  subject(:buffer) { described_class.new(redis: redis, key: key, threshold: threshold) }

  let(:key) { 'votes' }
  let(:threshold) { 3 }
  let(:redis) { instance_double(Redis) }
  let(:lua_sha) { 'Lua42' }

  let(:item) { { post_id: 42, user_id: 1, vote_type: 'upvote' } }
  let(:serialized_item) { Oj.dump(item) }
  let(:items) do
    [{ 'post_id' => 42, 'user_id' => 1, 'vote_type' => 'upvote' },
     { 'post_id' => 42, 'user_id' => 2, 'vote_type' => 'downvote' },
     { 'post_id' => 42, 'user_id' => 3, 'vote_type' => 'upvote' }]
  end
  let(:serialized_items) { items.map { |i| Oj.dump(i) } }

  before do
    allow(redis).to receive(:script).with(:load, anything).and_return(lua_sha)
  end

  describe '#push' do
    before do
      allow(redis).to receive(:rpush).with(key, serialized_item)
      allow(redis).to receive(:evalsha).with(lua_sha, keys: [key], argv: [threshold])
    end

    context 'when the buffer is below threshold' do
      it 'pushes the item to Redis and returns nil' do
        expect(redis).to receive(:evalsha).and_return(nil)
        expect(buffer.push(item)).to be_nil
        expect(redis).to have_received(:rpush).with(key, serialized_item)
      end
    end

    context 'when the buffer reaches or exceeds threshold' do
      it 'pushes the item, flushes the buffer, and returns deserialized items' do
        expect(redis).to receive(:evalsha).and_return(serialized_items)
        expect(buffer.push(item)).to eq(items)
      end
    end
  end

  describe '#flushall' do
    before do
      allow(redis).to receive(:lrange).and_return(serialized_items)
      allow(redis).to receive(:del)
    end

    it 'returns all items in the buffer and deletes the key' do
      expect(buffer.flushall).to eq(items)
      expect(redis).to have_received(:lrange).with(key, 0, -1)
      expect(redis).to have_received(:del).with(key)
    end

    context 'when the buffer is empty' do
      it 'returns an empty array' do
        expect(redis).to receive(:lrange).and_return([])
        expect(buffer.flushall).to be_nil
      end
    end
  end
end
