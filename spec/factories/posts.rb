# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    title { "Sample Post" }
    content { "Sample post content." }
    user_id { 42 }
  end
end
