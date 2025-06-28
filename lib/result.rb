# frozen_string_literal: true

# Manage Success and Failure
module Result
  def self.included(base)
    base.extend(ClassMethods)
    base.prepend Result::ServiceBase
  end

  def success(value)
    Result::Success.new(value)
  end
  alias Success success

  def failure(error)
    Result::Failure.new(error)
  end
  alias Failure failure

  # Class Methods
  module ClassMethods
    def attributes(*names)
      @attributes ||= Set.new
      @attributes.merge(names)

      attr_accessor(*names)
    end

    def attribute_names
      Array(@attributes || [])
    end

    def call(*args)
      result = new(*args).call

      if block_given?
        yield ResultHandler.new(result)
      else
        result
      end
    end
  end

  # Sucess Class
  class Success
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def success?
      true
    end
  end

  # Failure Class
  class Failure
    attr_reader :error

    def initialize(error)
      @error = error
    end

    def success?
      false
    end
  end

  # Handle Success and Failure
  class ResultHandler
    def initialize(result)
      @result = result
    end

    def success(&block)
      block.call(@result.value) if @result.success?
    end

    def failure(&block)
      block.call(@result.error) unless @result.success?
    end
  end

  # Service Base
  module ServiceBase
    def initialize(opts = {})
      opts.transform_keys!(&:to_sym)

      self.class.attribute_names.each do |name|
        instance_variable_set("@#{name}", opts[name])
      end
    end
  end
end
