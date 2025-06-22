# warn_indent: true
# frozen_string_literal: true

# Post Model
class Post < Sequel::Model
  include ApplicationModel

  def validate
    super
    validates_presence %i[title content user_id]
    validates_length_range 4..155, :title
  end
end
