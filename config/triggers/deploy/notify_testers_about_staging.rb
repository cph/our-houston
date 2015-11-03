Houston.config do
  on "deploy:completed" do |deploy|
    project = deploy.project
    if deploy.environment == "staging" && deploy.branch && project.on_github?
      pr_deployed = project.repo.pull_requests.find { |pr| pr.head.ref == deploy.branch }
      if pr_deployed
        on_staging = project.repo.issues(labels: "on-staging").map(&:number)
        on_staging.each do |pr_number|
          project.repo.remove_label_from("on-staging", pr_number) unless pr_number == pr_deployed.number
        end
        if on_staging.member?(pr_deployed.number)
          Houston.observer.fire "staging:updated", deploy, pr_deployed
        else
          project.repo.add_label_to "on-staging", pr_deployed
          Houston.observer.fire "staging:changed", deploy, pr_deployed
        end
      end
    end
  end

  on "staging:changed" do |deploy, pr|
    slack_send_message_to ":star2: The Pull Request #{slack_link_to_pull_request(pr)} is now on *#{deploy.project.slug}* Staging", "#testing"
  end

  on "staging:updated" do |deploy, pr|
    slack_send_message_to "New commits have been deployed for #{slack_link_to_pull_request(pr)} on *#{deploy.project.slug}* Staging", "#testing"
  end
end
