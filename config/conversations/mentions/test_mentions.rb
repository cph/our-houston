Houston::Slack.config do
  overhear(/itsm[\s:](?<number>\d+)\b/i) do |e|
    alert = Houston::Alerts::Alert.where(type: "itsm", number: e.match[:number]).first
    e.unfurl slack_alert_attachment(alert)
  end

  overhear(/cve[\s:](?<number>\d+)\b/i) do |e|
    alert = Houston::Alerts::Alert.where(type: "cve", number: e.match[:number]).first
    e.unfurl slack_alert_attachment(alert)
  end

  overhear(/(?:err|exception)[\s:](?<number>\d+)\b/i) do |e|
    alert = Houston::Alerts::Alert.where(type: "err", number: e.match[:number]).first
    e.unfurl slack_alert_attachment(alert)
  end

  overhear(/alert (?<number>\d+)\b/i) do |e|
    Houston::Alerts::Alert.where(number: e.match[:number]).each do |alert|
      e.unfurl slack_alert_attachment(alert)
    end
  end

  overhear(/\b(?<task>\d+[a-z]+)\b/i) do |e|
    next unless e.user && e.user.developer?
    tasks = Task.joins(:ticket)

    if project = e.channel.name != "test" && Project.find_by_slug(e.channel.name)
      tasks = tasks.where(Ticket.arel_table[:project_id].eq(project.id))
    else
      tasks = tasks.merge(Ticket.open)
    end

    tasks.with_shorthand(e.match[:task]).each do |task|
      e.unfurl slack_task_attachment(task)
    end
  end
end
