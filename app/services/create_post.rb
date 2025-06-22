# warn_indent: true
# frozen_string_literal: true

# Create Post
class CreatePost
  include Result

  attributes :title, :content, :user_id

  def call
    post = Post.new(title: title, content: content, user_id: user_id)

    if post.valid?
      Success(post)
    else
      Failure(post.errors)
    end
  end
end
