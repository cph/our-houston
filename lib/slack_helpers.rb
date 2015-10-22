SLACK_USERNAME_FOR_USER = {
  BEN => "@bengovero",
  BOB => "@boblail",
  LUKE => "@luke",
  MEAGAN => "@meagan",
  BRAD => "@brad",
  ORDIE => "@ordiep",
  JEREMY => "@jeremy",
  CHASE => "@chase",
  MATT => "@kobsy"
}.freeze

def slack_send_message_to(message, channel, options={})
  if channel.is_a?(User)
    channel = SLACK_USERNAME_FOR_USER[channel.email]

    unless channel
      Rails.logger.info "\e[34m[slack:say] I don't know the Slack username for #{channel.email}\e[0m"
      return
    end
  end

  # In development, we'll send messages for specific users
  # to public channels that shadow the direct-message channels.
  # This just lets us troubleshoot Houston
  if Rails.env.development?
    channel.gsub! /^@/, "#user-"
  end

  if options.delete(:as) == :github
    options.merge!(
      as_user: false,
      username: "github",
      icon_url: "https://slack.global.ssl.fastly.net/5721/plugins/github/assets/service_128.png")
  end

  Rails.logger.debug "\e[95m[slack:say] #{channel}: #{message}\e[0m"
  Houston::Slack.send message, options.merge(channel: channel)
end

def alert_unfurl_url(alert)
  "http://#{Houston.config.host}/#{alert.type}/#{alert.number}"
end

def slack_alert_attachment(alert, options={})
  unfurl_url = alert_unfurl_url(alert)
  title = slack_link_to(alert.summary, unfurl_url)
  title << " {{#{alert.type}:#{alert.number}}}" if alert.number
  attachment = {
    fallback: "#{slack_escape(alert.summary)} - #{unfurl_url} - #{alert.number}",
    title: title,
    color: slack_project_color(alert.project) }

  attachment.merge!(text: alert.text) unless alert.text.blank?
  attachment
end

def slack_link_to_pull_request(pr)
  if pr.is_a?(::Github::PullRequest) # Houston Pull Request
    slack_link_to "##{pr.number} #{pr.title}", pr.url
  else # GitHub Payload
    url = pr._links ? pr._links.html.href : pr.pull_request.html_url
    slack_link_to "##{pr.number} #{pr.title}", url
  end
end

def slack_link_to(message, url)
  return message unless url
  "<#{url}|#{slack_escape(message)}>"
end

def slack_escape(message)
  message.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "gt;").gsub(/[\r\n]/, " ")
end
