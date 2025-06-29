# frozen_string_literal: true

require 'connection_pool'
require 'logger'
require 'oj'
require 'redis'
require 'singleton'

class Cache
  include Singleton

  def initialize
    @logger = Logger.new($stdout)
    @pool = ConnectionPool.new(size: ENV.fetch('REDIS_POOL_SIZE', 5), timeout: 5) do
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    end

    graceful_shutdown
  end

  def increment(key, ttl: nil)
    with_redis do |conn|
      conn.incr(key).tap { conn.expire(key, ttl) if ttl }
    end
  end

  def get(key)
    with_redis do |conn|
      data = conn.get(key)
      data && Oj.load(data, mode: :object)
    end
  end

  def del(key)
    with_redis { |conn| conn.del(key) }
  end

  def fetch(key, ttl: nil, &block)
    with_redis do |conn|
      if conn.exists?(key)
        Oj.load(conn.get(key), mode: :object)
      else
        yield.tap { |data| conn.set(key, Oj.dump(data, mode: :object), ex: ttl) }
      end
    end
  end

  def fetch_multi(keys)
    with_redis do |conn|
      conn.mget(*keys).filter_map do |value|
        value ? Oj.load(value, mode: :object) : nil
      end
    end
  end

  def flushall
    with_redis { |conn| conn.flushall }
  end

  private

  attr_reader :pool, :logger

  def with_redis
    pool.with { |conn| yield conn }
  rescue Redis::BaseConnectionError => e
    logger.error('Failed to connect to Redis')
  rescue StandardError => e
    logger.error(e.message)
  end

  def graceful_shutdown
    at_exit do
      pool.shutdown { |conn| conn.close }
    end
  end
end
