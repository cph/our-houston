module ReleaseExt
  extend ActiveSupport::Concern

  def pull_requests
    Github::PullRequest.joins(:commits).where(Commit.arel_table[:sha].in(commits.pluck(:sha)))
  end

end
