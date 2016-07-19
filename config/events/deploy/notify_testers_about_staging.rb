Houston.config do
  on "deploy:succeeded" => "deploy:slack-testers-when-staging-changes" do
    project = deploy.project
    if deploy.environment == "staging" && deploy.branch && project.on_github?
      if pr_deployed = project.pull_requests.open.find_by(head_ref: deploy.branch)

        # Remove the `on-staging` label from any other pull requests
        on_staging = project.repo.issues(labels: "on-staging").map(&:number)
        on_staging.each do |pr_number|
          project.repo.remove_label_from("on-staging", pr_number) unless pr_number == pr_deployed.number
        end

        # Raise events about changes to Staging
        if on_staging.member?(pr_deployed.number)
          Houston.observer.fire "staging:updated", deploy: deploy, pull_request: pr_deployed
        else
          project.repo.add_label_to "on-staging", pr_deployed
          Houston.observer.fire "staging:changed", deploy: deploy, pull_request: pr_deployed
        end
      end
    end
  end

  on "staging:changed" => "deploy:slack-testers-about-new-pull-request-on-staging" do
    slack_send_message_to ":star2: #{slack_link_to_pull_request(pr)} is now on *#{deploy.project.slug}* Staging", "#testing"
  end

  on "staging:updated" => "deploy:slack-testers-about-new-commits-on-staging" do
    slack_send_message_to "New commits have been deployed for #{slack_link_to_pull_request(pr)} on *#{deploy.project.slug}* Staging", "#testing"
  end
end
