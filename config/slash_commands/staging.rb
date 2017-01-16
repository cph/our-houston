Houston::Slack.config do
  slash("staging") do |e|
    if e.message.blank?
      pulls = Houston.github.org_issues(Houston::Commits.config.github[:organization], labels: "on-staging", filter: "all")
      if pulls.none?
        message = "There are no pull requests on Staging"
      else
        message = ""
        pulls.each do |pull|
          message << "*#{pull.repository.name.capitalize}* has #{slack_link_to_pull_request(pull)} on Staging\n"
          pull.labels.each { |lb| message << "`#{lb.name}` " }
          message << "\n"
        end
      end
    else
      project = Project.find_by_slug e.message
      if project
        pull = list_pull_requests_on_staging_for_project(project).first
        if pull.nil?
          message = "*#{project.slug}* doesn't have a pull request on Staging"
        else
          message = "*#{project.slug}* has #{slack_link_to_pull_request(pull)} on Staging\n"
          pull.labels.each { |lb| message << "`#{lb.name}` " }
          message << "\n"
        end
      else
        message = "I don't have a project with the slug *#{e.message}*"
      end
    end
    e.respond! message
  end
end

def list_pull_requests_on_staging_for_project(project)
  Houston.github.list_issues(
      "cph/#{project.slug}",
      labels: "on-staging",
      filter: "all")
    .select(&:pull_request)
end
