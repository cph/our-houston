Houston::Conversations.config.listen_for "which VMs need to be patched?" do |e|
  e.reply "I'll check..."
  e.reply list_engineyard_vms_that_need_patches
end
