require "graphql/client"
require "graphql/client/http"

module GitHubQL
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      {
        # Preview the Repository Vulnerability Alerts API
        # https://developer.github.com/changes/2018-04-24-preview-dependency-graph-and-vulnerability-hooks/#repository-vulnerability-alerts-graphql-api
        "Accept" => "application/vnd.github.vixen-preview",
        "Authorization" => "bearer #{ENV["HOUSTON_GITHUB_ACCESS_TOKEN"]}"
      }
    end
  end

  class << self
    def reload_schema!
      GraphQL::Client.dump_schema(GitHubQL::HTTP, schema_path)
      remove_instance_variable :@schema if instance_variable_defined?(:@schema)
    end

    def schema
      return @schema if instance_variable_defined?(:@schema)
      reload_schema! unless File.exists?(schema_path)
      @schema = GraphQL::Client.load_schema(schema_path)
    end

    def client
      @client ||= GraphQL::Client.new(schema: schema, execute: GitHubQL::HTTP)
    end

    def vulnerability_alerts(repos: nil)
      repos ||= Project.unretired.github_repo_names

      query_string = repos.sort.map { |r| "repo:#{r}" }.join(" ")
      result = client.query(VulnerabilityAlertQuery, variables: { "queryString" => query_string  })
      (result.data&.search&.edges || []).each_with_object([]) do |edge, alerts|
        repo = edge.node
        repo.vulnerability_alerts.nodes.each do |alert|
          next if alert.dismissed_at

          alerts.push(
            id: alert.id,
            repo: repo.name_with_owner,
            dependency: alert.security_vulnerability.package.name,
            affected_versions: alert.security_vulnerability.vulnerable_version_range,
            fixed_in_version: alert.security_vulnerability.first_patched_version&.identifier,
            names: alert.security_advisory.identifiers.map(&:value),
            url: alert.security_advisory.references.first.url)
        end
      end
    end

    private def schema_path
      @schema_path ||= Houston.root.join("config/github-graphql-schema.json").to_s
    end
  end

  VulnerabilityAlertQuery = GitHubQL.client.parse <<~GraphQL
    query($queryString:String!) {
      rateLimit {
        cost
        remaining
        resetAt
      }
      search(query:$queryString, type:REPOSITORY, first:100) {
        repositoryCount
        pageInfo {
          endCursor
          startCursor
        }
        edges {
          node {
            ... on Repository {
              nameWithOwner
              vulnerabilityAlerts(first: 100) {
                nodes {
                  dismissedAt
                  id
                  packageName
                  securityAdvisory {
                    id
                    ghsaId
                    identifiers {
                      type
                      value
                    }
                    references {
                      url
                    }
                  }
                  securityVulnerability {
                    firstPatchedVersion {
                      identifier
                    }
                    package {
                      name
                    }
                    vulnerableVersionRange
                  }
                }
              }
            }
          }
        }
      }
    }
  GraphQL

end
