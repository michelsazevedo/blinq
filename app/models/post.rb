# frozen_string_literal: true

# Post Model
class Post < Sequel::Model
  include ApplicationModel

  one_to_many :votes

  def self.update_vote_counters(votes)
    votes.each do |post_id, attributes|
      where(id: post_id).update(**attributes)
    end
  end

  def validate
    super
    validates_presence %i[title content user_id]
    validates_length_range 4..155, :title
  end
end
