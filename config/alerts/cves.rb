def repo_name_from_url(url)
  url[/\Agit@github\.com:(.*)\.git\Z/, 1] || url[/\Agit:\/\/github.com\/(.*)\.git\Z/, 1]
end

# Besides CVE, GitHub also prefixes identifiers with WS for WhiteSource, apparently
CVE_IDENTIFIER = /\A(?:CVE|WS)\-(?<year>\d{4})\-(?<number>\d+)\z/

Houston::Alerts.config.sync :open, "cve", every: "5m", icon: "fa-bank" do
  project_slug_by_repo_name = Hash[Project.unretired.on_github
    .pluck("props->>'git.location'", :slug)
    .map { |url, slug| [repo_name_from_url(url), slug] }]

  GitHubQL.vulnerability_alerts(repos: project_slug_by_repo_name.keys).map { |alert|
    cve = CVE_IDENTIFIER.match(alert.fetch(:name))
    raise NotImplementedError, "Expected #{alert.fetch(:name)} to look like a CVE identifier" unless cve

    { key: alert.fetch(:id),
      number: cve[:number].to_i,
      project_slug: project_slug_by_repo_name.fetch(alert.fetch(:repo)),
      summary: "Upgrade #{alert.fetch(:dependency)} to #{alert.fetch(:fixed_in_version)}",
      environment_name: "production",
      url: alert.fetch(:url) } }
end
