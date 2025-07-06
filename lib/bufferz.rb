# frozen_string_literal: true

## Buffers items in Redis using a list and flushes them in batches using a Lua script
#
# The buffer is flushed automatically once it reaches the configured threshold
# The flush uses a Lua script to atomically check the length, fetch and delete the items
#
# Example:
#   buffer = Bufferz.new(key: 'buffer', threshold: 10)
#   buffer.push({ user_id: 42, post_id: 1, vote_type: 'upvote' }) # => nil if under threshold
#   # when buffer reaches threshold:
#   # => returns array of flushed items
class Bufferz
  attr_reader :redis, :key, :threshold, :flush

  # Lua script that atomically flushes the buffer when the threshold is reached
  LUA_FLUSH_SCRIPT = <<~LUA
    local key = KEYS[1]
    local threshold = tonumber(ARGV[1])

    local length = redis.call("LLEN", key)
    if length < threshold then
      return nil
    end

    local items = redis.call("LRANGE", key, 0, -1)
    redis.call("DEL", key)
    return items
  LUA

  ## Initializes a new Bufferz instance
  #
  # @param redis [Redis] the Redis client (defaults to Cache.instance)
  # @param key [String] the Redis key to store buffered items
  # @param threshold [Integer] the item count threshold to trigger flush
  def initialize(redis: Cache.instance, key: 'buffer', threshold: 100)
    @redis = redis
    @key = key
    @threshold = threshold

    @flush = @redis.script(:load, LUA_FLUSH_SCRIPT)
  end

  ## Pushes an item to the Redis buffer
  # If the number of items in the buffer reaches the threshold, all items are flushed and returned
  #
  # @param item [Object] any serializable object to store
  # @return [Array<Object>|nil] flushed items or nil if threshold not met
  def push(item)
    redis.rpush(key, Oj.dump(item))

    redis.evalsha(flush, keys: [key], argv: [threshold]).then do |items|
      items&.map { |json| Oj.load(json) }
    end
  end

  ## Forces flushing all items in the buffer, regardless of threshold
  #
  # @return [Array<Object>|nil] the flushed items, or nil if buffer was empty
  def flushall
    redis.lrange(key, 0, -1).then do |items|
      redis.del(key)
      items.empty? ? nil : items.map { |item| Oj.load(item) }
    end
  end
end
