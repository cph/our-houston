Houston.config.at "7:30am", "report:weekly:engineyard:patches", every: :monday do
  slack_send_message_to list_engineyard_vms_that_need_patches, "ops"
end
