OPEN_TICKETS_IN_MY_GROUPS_VIEW_ID = 78445

# Sync FreshService tickets as Alerts
Houston::Alerts.config.sync :open, "freshservice", every: "60s", icon: "fa-bolt" do
  response = $freshservice.get("helpdesk/tickets/view/#{OPEN_TICKETS_IN_MY_GROUPS_VIEW_ID}.json")
  tickets = MultiJson.load(response.body)
  unless tickets.is_a?(Array)
    raise NotImplementedError, "Unexpected response: #{tickets.inspect}"
  end

  tickets.map { |ticket|
    subject = ticket.fetch("subject")
    project_slug, summary = subject.scan(/^\s*\[([^\]]+)\]\s*(.*)$/)[0]
    number = ticket.fetch("display_id")
    { key: ticket.fetch("id").to_s,
      number: number,
      project_slug: project_slug ? project_slug.downcase : "no-project",
      can_change_project: true,
      summary: summary || subject,
      environment_name: "production",
      text: ticket.fetch("description"),
      url: "https://cph.freshservice.com/helpdesk/tickets/#{number}" } }
end
