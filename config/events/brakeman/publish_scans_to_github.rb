# Until we're closer to having passing scores on these
# we won't publish them to GitHub.
#
# The intention is to make commit status reports on GitHub
# more valuable as a heuristic.

# Houston.config.on "brakeman:scan:complete" do
#   begin
#     repo = scan.project.repo
#     return unless repo.respond_to? :create_commit_status
#     repo.create_commit_status(scan.sha, scan)
#
#   rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
#     Houston.report_exception $!, parameters: {
#       brakeman_scan_id: scan.id,
#       project: scan.project.slug,
#       method: "publish_status_to_github" }
#   end
# end
