module GfmarkdownHelper
  include EmojiHelper

  def gfmdown(text)
    return "" if text.blank?
    emojify Kramdown::Document.new(text, input: "GFM").to_html.html_safe
  end

end
