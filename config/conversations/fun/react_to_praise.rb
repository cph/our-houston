praise = %w{
  thank\ you
  you\ are\ awesome
  you\ are\ the\ best
  nice\ work
  nice\ job
  good\ work
  good\ job
}.freeze

Houston::Conversations.config do
  listen_for *praise, context: { in: :slack } do |e|
    emoji = %w{simple_smile grin +1}.sample

    if e.user
      compliments = e.user.props.fetch("slack.compliments", 0) + 1
      e.user.update_prop! "slack.compliments", compliments
      emoji = "heart" if compliments == 8
      emoji = %w{heart yellow_heart} if compliments == 16
      emoji = %w{heart yellow_heart heartpulse} if compliments == 32
      emoji = %w{heart yellow_heart heartpulse sparkling_heart} if compliments == 64
    end

    e.react emoji
  end

  listen_for "i love you" do |e|
    e.react "blush"
  end
end
