Houston::Slack.config do
  slash("staging") do |e|
    if e.text.blank?
      pulls = Houston.github.org_issues(Houston.config.github[:organization], labels: "on-staging", filter: "all")
      if pulls.none?
        message = "There are no pull requests on Staging"
      else
        message = ""
        pulls.each do |pull|
          message << "*#{pull.repository.name.capitalize}* has #{slack_link_to_pull_request(pull)} on Staging\n"
          pull.labels.each { |lb| message << "`#{lb.name}` " }
          message << checkbox_emojis(pull)
        end
      end
    else
      project = Project.find_by_slug e.text
      if project
        pull = list_pull_requests_on_staging_for_project(project).first
        if pull.nil?
          message = "*#{project.slug}* doesn't have a pull request on Staging"
        else
          message = "*#{project.slug}* has #{slack_link_to_pull_request(pull)} on Staging\n"
          pull.labels.each { |lb| message << "`#{lb.name}` " }
          message << checkbox_emojis(pull)
        end
      else
        message = "I don't have a project with the slug *#{e.text}*"
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

def checkbox_emojis(pull_request)
  " *#{unchecked(pull_request)}* :white_large_square: *#{checked(pull_request)}* :white_check_mark:\n"
end

def checked(pull_request)
  pull_request.body.to_s.scan("[x]").count
end

def unchecked(pull_request)
  pull_request.body.to_s.scan("[ ]").count
end
