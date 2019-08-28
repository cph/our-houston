def repo_name_from_url(url)
  url[/\Agit@github\.com:(.*)\.git\Z/, 1] || url[/\Agit:\/\/github.com\/(.*)\.git\Z/, 1]
end

# Besides CVE, GitHub also prefixes identifiers with WS for WhiteSource, apparently
CVE_IDENTIFIER = /\A(?:CVE|WS)\-(?<year>\d{4})\-(?<number>\d+)\z/
GHSA_IDENTIFIER = /\AGHSA-(?<identifier>[a-z0-9\-]+)\z/

Houston::Alerts.config.sync :open, "cve", every: "5m", icon: "fa-bank" do
  project_slug_by_repo_name = Hash[Project.unretired.on_github
    .pluck("props->>'git.location'", :slug)
    .map { |url, slug| [repo_name_from_url(url), slug] }]

  GitHubQL.vulnerability_alerts(repos: project_slug_by_repo_name.keys).map { |alert|
    ghsa_match = alert.fetch(:names, []).map { |identifier|
      GHSA_IDENTIFIER.match(identifier)
    }.compact.first
    ghsa = GithubSecurityAdvisory.find_or_create_by(ghsa_id: ghsa_match[:identifier]) unless ghsa_match.nil?

    # Do we need to continue using this? Does every advisory from GH contain a GHSA id?
    cve = alert.fetch(:names, []).map { |identifier|
      CVE_IDENTIFIER.match(identifier)
    }.compact.first

    number = cve&.[](:number) || ghsa&.number

    raise NotImplementedError, "Expected #{alert.fetch(:names, []).join(", ")} to look like a CVE identifier" unless number

    { key: alert.fetch(:id),
      number: number.to_i,
      project_slug: project_slug_by_repo_name.fetch(alert.fetch(:repo)),
      summary: "Upgrade #{alert.fetch(:dependency)} to #{alert.fetch(:fixed_in_version)}",
      environment_name: "production",
      url: alert.fetch(:url) } }
end
