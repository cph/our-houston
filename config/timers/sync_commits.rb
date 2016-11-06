Houston.config.every "day at 2:00am", "sync:commits" do
  SyncCommitsJob.run!
end
