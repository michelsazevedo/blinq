# frozen_string_literal: true

require 'connection_pool'

## RabbitMQ wrapper
class MessageQueue
  ## Initializes the RabbitMQ connection and channel pool
  #
  # @param logger [Logger] The logger to use (defaults to Logger.new)
  # @param heartbeat [Integer] Heartbeat interval in seconds
  def initialize(logger: nil, heartbeat: 10)
    @logger = logger || Logger.new($stdout)
    @connection_pool = ConnectionPool.new(size: ENV.fetch('RABBITMQ_POOL_SIZE', 5), timeout: 5) do
      conn = Bunny.new(ENV.fetch('RABBITMQ_URL'), automatically_recover: true, heartbeat: heartbeat)
      conn.start
      channels = ENV.fetch('CHANNEL_POOL_SIZE', 5).times.map { conn.create_channel }
      { connection: conn, channels: channels, channel_mutex: Mutex.new, queues: {} }
    end

    graceful_shutdown
  end

  ## Publishes a message to the specified RabbitMQ queue
  #
  # @param queue_name [String] The queue's name
  # @param message [Hash] The message to send
  # @param durable [Boolean] Whether the queue should survive broker restart
  def publish(queue_name, message, durable: true)
    @connection_pool.with do |resource|
      channel = resource[:channels].sample
      queue = resource[:channel_mutex].synchronize do
        resource[:queues][queue_name] ||= channel.queue(queue_name, durable: durable)
      end
      queue.publish(Oj.dump(message), persistent: true)
    end
  rescue StandardError => e
    @logger.error("Error to publish to #{queue_name}: #{e.message}")
  end

  ## Subscribes to a queue and processes messages using the given block
  #
  # @param queue_name [String] The name of the queue to subscribe to
  # @param durable [Boolean] Whether the queue is durable
  # @param manu_ack [Boolean] Whether to manually acknowledge messages
  # @param dlq [Boolean] Whether to enable dead-letter queue support
  #
  # @yield [data, delivery_info, properties, channel] The block that handles the message
  # @yieldparam data [Hash] The parsed message payload
  # @yieldparam delivery_info [Bunny::DeliveryInfo] Delivery info from Bunny
  # @yieldparam properties [Bunny::MessageProperties] Message properties
  # @yieldparam channel [Bunny::Channel] The channel used for ack/reject
  #
  # @return [void]
  def subscribe(queue_name, durable: true, manual_ack: false, dlq: false, &block)
    @connection_pool.with do |resource|
      channel = resource[:channels].sample
      resource[:channel_mutex].synchronize do
        dlq!(channel, queue_name, durable: durable) if dlq

        queue = resource[:queues][queue_name] ||= begin
          args = dlq ? { 'x-dead-letter-exchange' => '', 'x-dead-letter-routing-key' => "#{queue_name}.dlq" } : {}
          channel.queue(queue_name, durable: durable, arguments: args)
        end

        queue.subscribe(manual_ack: manual_ack, block: false) do |delivery_info, properties, payload|
          block.call(Oj.load(payload), delivery_info, properties, channel)
          channel.ack(delivery_info.delivery_tag) if manual_ack
        rescue StandardError => e
          @logger.error("Consumer error on #{queue_name}: #{e.message}")
          channel.reject(delivery_info.delivery_tag, requeue = false) if manual_ack && dlq
        end
      end
    end
  end

  ## Gracefully shuts down the RabbitMQ connections and channels
  #
  # @return [void]
  def graceful_shutdown
    at_exit do
      @connection_pool.with do |resource|
        resource[:channels].each { |chanel| chanel.close if chanel.open? }
        resource[:connection].close if resource[:connection].open?
      end
    end
  end

  private

  ## Declares a dead-letter queue for the given queue
  #
  # @param channel [Bunny::Channel] The Bunny channel
  # @param queue_name [String] The base name of the queue
  # @param durable [Boolean] Whether the DLQ should be durable
  #
  # @return [void]
  def dql!(channel, queue_name, durable:)
    channel.queue("#{queue_name}.dlq", durable: durable)
  end
end
