# frozen_string_literal: true

# Buffers
class Bufferz
  attr_reader :redis, :key, :threshold, :flush

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

  def initialize(redis: Cache.instance, key: 'buffer', threshold: 100)
    @redis = redis
    @key = key
    @threshold = threshold

    @flush = @redis.script(:load, LUA_FLUSH_SCRIPT)
  end

  def push(item)
    redis.rpush(key, Oj.dump(item))

    redis.evalsha(flush, keys: [key], argv: [threshold]).then do |items|
      items&.map { |json| Oj.load(json) }
    end
  end

  def flushall
    redis.lrange(key, 0, -1).then do |items|
      redis.del(key)
      items.empty? ? nil : items.map { |item| Oj.load(item) }
    end
  end
end
