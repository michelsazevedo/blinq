# frozen_string_literal: true

# Application Model
module ApplicationModel
  def self.included(base)
    base.plugin :timestamps, update_on_create: true
    base.plugin :validation_helpers
    base.plugin :json_serializer

    base.class_eval do
      alias_method :save!, :save
    end
  end
end
