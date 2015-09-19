# Sync ITSMs as Alerts
Houston::Alerts.config.sync :open, "itsm", every: "60s" do
  ITSM::Issue.open
    .map { |issue|
      project_slug, summary = issue.summary.scan(/^\s*\[([^\]]+)\]\s*(.*)$/)[0]
      text = ActionView::Base.full_sanitizer.sanitize(issue.notes) rescue issue.notes
      summary ||= issue.summary
      summary = "No summary provided" if summary.blank?
      { key: issue.key,
        number: issue.number,
        project_slug: (project_slug && project_slug.downcase),
        summary: summary,
        checked_out_by_email: issue.assigned_to_email,
        checked_out_remotely: false,
        can_change_project: true,
        requires_verification: true,
        environment_name: "production",
        text: text.strip.gsub(/\n+/, " "),
        url: issue.url
      } }
end
