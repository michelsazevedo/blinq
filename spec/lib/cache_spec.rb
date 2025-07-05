# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cache do
  let(:redis) { instance_double(Redis) }
  let(:pool) { instance_double(ConnectionPool) }
  let(:logger) { instance_double(Logger, error: nil) }
  let(:pool_size) { 5 }
  let(:key) { 'post:42:upvote' }

  before do
    allow(ConnectionPool).to receive(:new).and_return(pool)
    allow(pool).to receive(:with).and_yield(redis)
    allow_any_instance_of(described_class).to receive(:graceful_shutdown)

    Cache.configure(logger: logger)
  end

  after do
    Cache.instance_variable_set(:@instance, nil)
  end

  describe '.configure' do
    it 'initializes the cache instance with provided parameters' do
      expect(Cache.instance).to be_a(Cache)
      expect(ConnectionPool).to have_received(:new).with(size: pool_size, timeout: 5)
    end
  end

  describe '#increment' do
    before { allow(redis).to receive(:incr).with(key).and_return(1) }

    context 'when TTL is provided' do
      before { allow(redis).to receive(:expire).with(key, 60) }

      it 'increments a key and sets TTL if provided' do
        expect(Cache.instance.increment(key, ttl: 60)).to eq(1)
        expect(redis).to have_received(:expire).with(key, 60)
      end
    end

    context 'when TTL is not provided' do
      before { allow(redis).to receive(:expire).with(key, nil) }
      it 'increments a key' do
        expect(Cache.instance.increment(key)).to eq(1)
        expect(redis).to have_received(:incr)
      end
    end

    context 'when Redis connection errors gracefully' do
      it 'logs connection error' do
        allow(pool).to receive(:with).and_raise(Redis::BaseConnectionError, 'connection error')
        Cache.instance.increment(key)
        expect(logger).to have_received(:error).with('Failed to connect to Redis: connection error')
      end
    end
  end

  describe '#get' do
    context 'when the value exists' do
      let(:post) { create(:post) }
      let(:serialized_data) { Oj.dump(post, mode: :object) }
      let(:key) { "post:#{post.id}" }

      before do
        allow(redis).to receive(:get).with(key).and_return(serialized_data)
        allow(Oj).to receive(:load).with(serialized_data, mode: :object).and_return(post)
      end
      it 'retrieves and deserializes a value' do
        expect(Cache.instance.get(key)).to eq(post)
      end
    end

    context 'when the value does not exists' do
      let(:key) { 'post:42' }

      before { allow(redis).to receive(:get).with(key).and_return(nil) }
      it 'returns nil if key does not exist' do
        expect(Cache.instance.get(key)).to be_nil
      end
    end
  end

  describe '#del' do
    before { allow(redis).to receive(:del).with(key).and_return(1) }
    it 'deletes a key and returns the number of keys deleted' do
      expect(Cache.instance.del(key)).to eq(1)
    end
  end

  describe '#fetch' do
    let(:post) { create(:post) }
    let(:serialized_data) { Oj.dump(post, mode: :object) }
    let(:key) { "post:#{post.id}" }

    context 'when the value exists' do
      before do
        allow(redis).to receive(:exists?).with(key).and_return(true)
        allow(redis).to receive(:get).with(key).and_return(serialized_data)
        allow(redis).to receive(:set)
        allow(Oj).to receive(:load).with(serialized_data, mode: :object).and_return(post)
      end

      it 'returns cached value if key exists' do
        expect(Cache.instance.fetch(key) { post }).to eq(post)
        expect(redis).not_to have_received(:set)
      end
    end

    context 'when the value does not exists' do
      before do
        allow(redis).to receive(:exists?).with(key).and_return(false)
        allow(redis).to receive(:set).with(key, serialized_data, ex: 60)
        allow(Oj).to receive(:dump).with(post, mode: :object).and_return(serialized_data)
      end
      it 'computes and caches value if key does not exist' do
        expect(Cache.instance.fetch(key, ttl: 60) { post }).to eq(post)
        expect(redis).to have_received(:set).with(key, serialized_data, ex: 60)
      end
    end
  end
end
