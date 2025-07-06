# frozen_string_literal: true

# Consuming vote messages from RabbitMQ
class VoteWorker
  def initialize(buffer:, queue_name: 'votes', logger: Sinatra.logger)
    @buffer = buffer
    @logger = logger
    @queue_name = queue_name
  end

  def perform
    Sinatra.queue.subscribe(@queue_name, durable: true, manual_ack: true, dlq: true) do |data, _, _, _|
      flushed = @buffer.push(data)

      if flushed
        @logger.info("Flushing #{flushed.size} votes")
        Vote.safe_multi_insert(flushed)
      end
    rescue StandardError => e
      @logger.error("Failed to process vote: #{e.class} - #{e.message}")
      raise
    end
  end
end
