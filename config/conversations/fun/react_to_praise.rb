praise = %w{
  thanks
  thank\ you
  youre\ awesome
  youre\ the\ best
  nice\ work
  nice\ job
  good\ work
  good\ job
}.freeze

Houston::Slack.config do
  listen_for(/^(?:#{praise.join("|")})$/, [:downcase, :no_punctuation, :no_mentions, :no_emoji]) do |e|
    emoji = %w{simple_smile grin +1}.sample

    if e.user
      complements = e.user.view_options["slack.complements"].to_i + 1
      e.user.update_column :view_options, e.user.view_options.merge("slack.complements" => complements)
      emoji = "heart" if complements == 8
      emoji = %w{heart yellow_heart} if complements == 16
      emoji = %w{heart yellow_heart heartpulse} if complements == 32
      emoji = %w{heart yellow_heart heartpulse sparkling_heart} if complements == 64
    end

    e.react emoji
  end

  listen_for(/^i love you$/, [:downcase, :no_punctuation, :no_mentions, :no_emoji]) do |e|
    e.react "blush"
  end
end
