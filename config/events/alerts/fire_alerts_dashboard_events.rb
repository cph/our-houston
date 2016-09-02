TEAMS_ON_EP_DASHBOARD = [1,3,6,8]

Houston.config do
  on "alert:create" => "alert:fire-new-on-opened" do
    project_ids = Project.where(team_id: TEAMS_ON_EP_DASHBOARD).pluck(:id)
    next unless project_ids.member? alert.project_id

    Houston.observer.fire "alerts:new"
  end

  on "alert:close" => "alert:fire-none-on-all-closed" do
    project_ids = Project.where(team_id: TEAMS_ON_EP_DASHBOARD).pluck(:id)
    next unless project_ids.member? alert.project_id

    unless Houston::Alerts::Alert.unsuppressed.open.where(project_id: project_ids).exists?
      Houston.observer.fire "alerts:none"
    end
  end
end
