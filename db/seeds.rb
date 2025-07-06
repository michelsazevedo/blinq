require 'net/http'
require 'nokogiri'
require_relative '../config/boot'

pages = 205
content_url = ''

2.upto(pages) do |page|
  response = Net::HTTP.get_response(URI.parse("#{content_url}/page/#{page}/".chomp))
  html = Nokogiri::HTML(response.body)

  titles = html.css('h3').map(&:text)
  contents = html.css('p.gh-card-excerpt').map(&:text)

  posts = titles.zip(contents).map do |title, content|
    { title: title, content: content, user_id: 42, upvotes: 0, downvotes: 0 }
  end

  puts Oj.dump({ page: page, posts: posts.count, error: nil })
  Post.multi_insert(posts)
rescue StandardError => e
  puts Oj.dump({ page: page, error: e.message })
end
