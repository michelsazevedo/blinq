# frozen_string_literal: true

require 'connection_pool'
require 'logger'
require 'oj'
require 'redis'

## A Redis-backed thread-safe cache wrapper with connection pooling
class Cache
  class << self
    attr_reader :instance

    ## Configures and initializes the global cache instance
    #
    # @param redis_url [String] Redis connection URL (default from ENV)
    # @param pool_size [Integer] Number of connections in the pool (default from ENV)
    # @param logger [Logger] Logger instance (defaults to Logger.new)
    #
    # @return [Cache] the initialized Cache instance
    def configure(logger: nil, redis_url: ENV['REDIS_URL'], pool_size: ENV['REDIS_POOL_SIZE'])
      @redis_url = redis_url || 'redis://localhost:6379'
      @pool_size = pool_size || 5
      @logger = logger || Logger.new($stdout)

      @instance = Cache.new(redis_url: @redis_url, pool_size: @pool_size, logger: @logger)
    end
  end

  def initialize(redis_url:, pool_size:, logger:)
    @logger = logger
    @pool = ConnectionPool.new(size: pool_size, timeout: 5) { Redis.new(url: redis_url) }

    graceful_shutdown
  end

  ## Increments the integer value of a key by 1
  #
  # @param key [String] the Redis key to increment
  # @param ttl [Integer, nil] optional TTL in seconds
  #
  # @return [Integer, nil] the new value after incrementing, or nil on failure
  def increment(key, ttl: nil)
    with_redis do |conn|
      conn.incr(key).tap { conn.expire(key, ttl) if ttl }
    end
  end

  ## Retrieves and deserializes a value from Redis
  #
  # @param key [String] the Redis key
  #
  # @return [Object|nil] the deserialized value or nil if not found
  def get(key)
    with_redis do |conn|
      data = conn.get(key)
      data && Oj.load(data, mode: :object)
    end
  end

  ## Deletes a key from Redis
  #
  # @param key [String] the key to delete
  #
  # @return [Integer|nil] number of keys deleted, or nil on failure
  def del(key)
    with_redis { |conn| conn.del(key) }
  end

  ## Retrieves a value or computes, stores, and returns it if not cached
  #
  # @param key [String] the cache key
  # @param ttl [Integer, nil] optional TTL in seconds
  # @yield return a block that computes the value if not cached
  #
  # @return [Object] the cached or computed value
  def fetch(key, ttl: nil)
    with_redis do |conn|
      if conn.exists?(key)
        Oj.load(conn.get(key), mode: :object)
      else
        yield.tap { |data| conn.set(key, Oj.dump(data, mode: :object), ex: ttl) }
      end
    end
  end

  ## Fetches multiple keys in a single call
  #
  # @param keys [Array<String>] the list of Redis keys
  #
  # @return [Array<Object>] array of loaded values (nil entries omitted)
  def fetch_multi(keys)
    with_redis do |conn|
      conn.mget(*keys).filter_map do |value|
        value ? Oj.load(value, mode: :object) : nil
      end
    end
  end

  ## Loads a Lua script into Redis and returns its SHA identifier
  #
  # @param script [String] the Lua script to load
  #
  # @return [String] the SHA1 of the script
  def load_script(script)
    with_redis { |conn| conn.script(:load, script) }
  end

  ## Pushes a serialized item onto the end of a Redis list
  #
  # @param key [String] Redis list key
  # @param item [Object] the item to serialize and push
  #
  # @return [Integer] the new length of the list
  def rpush(key, item)
    with_redis { |conn| conn.rpush(key, Oj.dump(item)) }
  end

  ## Executes a previously loaded Lua script by SHA
  #
  # @param flush [String] the SHA of the loaded script
  # @param keys [Array<String>] Redis keys used in the script
  # @param argv [Array<String>] Arguments passed to the script
  #
  # @return [Object] the result of the script execution
  def evalsha(flush, keys: [key, last_flush_key], argv: [threshold, interval, time])
    with_redis { |conn| conn.evalsha(flush, keys: keys, argv: argv) }
  end

  ## Retrieves a range of elements from a Redis list
  #
  # @param key [String] Redis list key
  # @param start [Integer] Start index
  # @param stop [Integer] Stop index
  #
  # @return [Array<String>] the list of items as strings
  def lrange(key, start, stop)
    with_redis { |conn| conn.lrange(key, start, stop) }
  end

  ## Clears all keys from Redis
  #
  # @return [String, nil] "OK" if successful, or nil on failure
  def flushall
    with_redis { |conn| conn&.flushall }
  end

  private

  attr_reader :pool, :logger

  def with_redis(&block)
    pool.with(&block)
  rescue Redis::BaseConnectionError => e
    @logger.error("Failed to connect to Redis: #{e.message}")
  rescue StandardError => e
    @logger.error(e.message)
  end

  def graceful_shutdown
    at_exit do
      pool.shutdown { |conn| conn&.close }
    end
  end

  configure
end
