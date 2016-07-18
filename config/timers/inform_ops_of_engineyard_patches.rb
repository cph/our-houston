Houston.config.at [:monday, "7:30am"], "report:weekly:engineyard:patches" do
  slack_send_message_to list_engineyard_vms_that_need_patches, "ops"
end
