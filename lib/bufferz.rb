# frozen_string_literal: true

## Buffers items in Redis using a list and flushes them in batches using a Lua script
#
# The buffer is flushed automatically once it reaches the configured threshold or when a time-based interval is met
# The flush uses a Lua script to atomically check the length, fetch and delete the items
#
# Example:
#   buffer = Bufferz.new(key: 'buffer', threshold: 10)
#   buffer.push({ user_id: 42, post_id: 1, vote_type: 'upvote' }) # => nil if under threshold
#   # when buffer reaches threshold:
#   # => returns array of flushed items
class Bufferz
  attr_reader :redis, :key, :threshold, :flush, :interval, :last_flush_key

  # Lua script that atomically flushes the buffer when the threshold is reached
  LUA_FLUSH_SCRIPT = <<~LUA
    local key = KEYS[1]
    local last_flush_key = KEYS[2]

    local threshold = tonumber(ARGV[1])
    local interval  = tonumber(ARGV[2])

    local length = redis.call("LLEN", key)
    local now = tonumber(redis.call("TIME")[1])
    local last_flush = tonumber(redis.call("GET", last_flush_key)) or 0

    if length >= threshold or (now - last_flush) >= interval then
      local items = redis.call("LRANGE", key, 0, -1)
      redis.call("DEL", key)
      redis.call("SET", last_flush_key, now)
      return items
    end
    return nil
  LUA

  ## Initializes a new Bufferz instance
  #
  # @param redis [Redis] the Redis client (defaults to Cache.instance)
  # @param key [String] the Redis key to store buffered items
  # @param threshold [Integer] the item count threshold to trigger flush
  # @param interval [Integer] The time (in seconds) to wait before flushing regardless of count
  def initialize(redis: Cache.instance, key: 'buffer', threshold: 10, interval: 120)
    @redis = redis
    @key = key
    @threshold = threshold
    @interval = interval
    @last_flush_key = "#{key}:last_flush"

    @flush = redis.load_script(LUA_FLUSH_SCRIPT)
  end

  ## Pushes an item to the Redis buffer
  # If the number of items in the buffer reaches the threshold or , all items are flushed and returned
  #
  # @param item [Object] any serializable object to store
  # @return [Array<Object>|nil] flushed items or nil if threshold not met
  def push(item)
    redis.rpush(key, Oj.dump(item))

    items = redis.evalsha(@flush, keys: [key, last_flush_key], argv: [threshold, interval, Time.now.to_i])
    items&.map { |item| Oj.load(item) }
  end

  ## Forces flushing all items in the buffer, regardless of threshold
  #
  # @return [Array<Object>|nil] the flushed items, or nil if buffer was empty
  def flushall
    items = redis.lrange(key, 0, -1)
    redis.del(key)

    items.empty? ? nil : items.map { |item| Oj.load(item) }
  end
end
