def slack_send_message_to(message, channels, options={})
  if channels.respond_to?(:each)
    channels.map do |channel|
      _slack_send_message_to_channel(message, channel, options)
    end
  else
    _slack_send_message_to_channel(message, channels, options)
  end
end

def _slack_send_message_to_channel(message, channel, options={})
  Houston.try({max_tries: 3},
            Errno::ECONNRESET,
            Errno::EPIPE,
            Errno::ETIMEDOUT,
            Net::OpenTimeout,
            Net::ReadTimeout,
            Net::SMTPServerBusy,
            EOFError) do
    if channel.respond_to?(:slack_channel)
      channel = channel.slack_channel

      unless channel
        Rails.logger.info "\e[34m[slack:say] I don't know the Slack username for #{channel.name}\e[0m"
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
end

def slack_replace_message_on_channel(ts, message, channel, options={})
  Houston.try({max_tries: 3},
            Errno::ECONNRESET,
            Errno::EPIPE,
            Errno::ETIMEDOUT,
            Net::OpenTimeout,
            Net::ReadTimeout,
            Net::SMTPServerBusy,
            EOFError) do
    if channel.respond_to?(:slack_channel)
      channel = channel.slack_channel

      unless channel
        Rails.logger.info "\e[34m[slack:say] I don't know the Slack username for #{channel.name}\e[0m"
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

    Rails.logger.debug "\e[95m[slack:update] #{channel}: #{message}\e[0m"
    Houston::Slack.connection.update_message ts, message, options.merge(channel: channel)
  end
end

def alert_unfurl_url(alert)
  "#{Houston.root_url}/#{alert.type}/#{alert.number}"
end

def feedback_unfurl_url(comment)
  "#{Houston.root_url}/feedback/#{comment.id}"
end

def slack_author_icon_for(user)
  "https://www.gravatar.com/avatar/#{Digest::MD5::hexdigest(user.email)}?r=g&d=retro"
end

def slack_github_comment_attachment(body)
  body = Slackdown.convert(body)

  { fallback: body, text: body, mrkdwn_in: %w{text} }
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

def slack_nanoconf_attachment(nanoconf, options={})
  { fallback: nanoconf.title,
    footer: "by #{nanoconf.presenter.name}",
    footer_icon: slack_author_icon_for(nanoconf.presenter),
    title: nanoconf.title,
    text: nanoconf.description }
end

def slack_chapel_service_attachment(service)
  { fallback: service.presenter.name,
    title: "Chapel service for #{service.date.strftime("%B %d")}",
    title_link: "#{Houston.root_url}/chapel_services/#{service.id}",
    text: service.description.gsub(/\*\*/, "*") }
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
