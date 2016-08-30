AUTOASSIGN_MAP = {
  "unite" => LUKE,
  "ledger" => LUKE,
  "members" => BEN,
  "our-houston" => BOB
}.freeze

Houston.config do
  on "alert:create" => "alert:autoassign" do
    next unless alert.project
    next if alert.checked_out_by
    next if alert.checked_out_remotely?

    email = AUTOASSIGN_MAP[alert.project.slug]
    user = User.find_by_email_address(email) if email
    alert.update_attribute :checked_out_by, user if user
  end
end
