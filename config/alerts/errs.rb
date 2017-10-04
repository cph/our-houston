# This is the date when we started composing the Alert key
# from problem.id and opened_at so that reopened problems
# are treated as new alerts.
ERRBIT_NEW_KEY_DATE = Time.new(2014, 11, 23).freeze

# The first time we sync errs after booting, we'll catch up
# by pulling down changes from the last week.
$errbit_since_changes_since = 1.week.ago

Houston::Alerts.config.sync :changes, "err", every: "45s", icon: "fa-bug" do
  app_project_map = Hash[Project
    .unretired
    .with_error_tracker("Errbit")
    .pluck("(props->>'errbit.appId')::integer", :id)]
  app_ids = app_project_map.keys

  Houston::Adapters::ErrorTracker::ErrbitAdapter.changed_problems(app_id: app_ids, since: $errbit_since_changes_since).map do |problem|
    key = problem.id.to_s
    key << "-#{problem.opened_at.to_i}" if problem.opened_at >= ERRBIT_NEW_KEY_DATE

    attrs = {
      key: key,
      project_id: app_project_map[problem.app_id],
      summary: problem.message,
      environment_name: problem.environment,
      text: problem.where,
      opened_at: problem.opened_at,
      closed_at: problem.resolved_at,
      destroyed_at: problem.deleted_at,
      url: problem.url }

    # Merged errs won't have a number
    attrs[:number] = problem.err_ids.min if problem.err_ids.any?

    attrs
  end.tap do

    # From now on, we should expect to sync every 45 seconds,
    # so we'll pull down changes from a smaller window.
    $errbit_since_changes_since = 3.minutes.ago
  end
end



# This syncs all errors back to the dawn of time
#
# # We don't want to pull in historical errs before this date
# ERRBIT_DAWN_OF_TIME = Time.new(2014, 9, 1).freeze
#
# Houston::Alerts.config.sync :all, "err", every: "75s" do
#   app_project_map = Hash[Project
#     .with_error_tracker("Errbit")
#     .pluck("(extended_attributes->'errbit_app_id')::integer", :id)]
#   app_ids = app_project_map.keys
#
#   Errbit.all_problems(app_id: app_ids, since: ERRBIT_DAWN_OF_TIME).map { |problem|
#     key = problem.id.to_s
#     key << "-#{problem.opened_at.to_i}" if problem.opened_at >= ERRBIT_NEW_KEY_DATE
#     { key: key,
#       number: problem.err_ids.min,
#       project_id: app_project_map[problem.app_id],
#       summary: problem.message,
#       environment_name: problem.environment,
#       text: problem.where,
#       opened_at: problem.opened_at,
#       closed_at: problem.resolved_at,
#       url: problem.url } }
# end
