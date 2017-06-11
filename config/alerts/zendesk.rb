ZENDESK_VIEW = (Rails.env.production? ? 70532187 : 69193308).freeze
ZENDESK_BRAND_PROJECT_MAP = {
  "360ledger" => "ledger",
  "360members" => "members",
  "360unite" => "unite",
  "biblestudybuilder" => "bsb",
  "bible101" => "bible101",
  "confirmationbuilder" => "confb",
  "lsb" => "lsb",
  "mysundaysolutions" => "musicmate",
  "oic" => "oic",
  "shepherdsstaff" => "shepherdsstaff",
  "concordiatech" => "ep-misc" }.freeze
ZENDESK_BRANDS = {}

Houston::Alerts.config.sync :open, "zendesk", every: "2m", icon: "fa-life-buoy" do

  if ZENDESK_BRANDS.empty?
    response = MultiJson.load($zendesk.get("brands").body)
    response["brands"].each do |brand|
      ZENDESK_BRANDS[brand["id"]] = ZENDESK_BRAND_PROJECT_MAP.fetch(brand["subdomain"], brand["subdomain"])
    end
  end

  # We want to pull down all the tickets that have been
  # assigned to the EP group. We can't do that directly
  # with the API, so we create a view in Zendesk that
  # performs that filter and use it here.
  response = MultiJson.load($zendesk.get("views/#{ZENDESK_VIEW}/tickets").body)
  response["tickets"].map { |ticket|
    { key: ticket["url"],
      number: ticket["id"],
      project_slug: ZENDESK_BRANDS[ticket["brand_id"]],
      can_change_project: true,
      summary: ticket["subject"],
      environment_name: "production",
      text: ticket["description"],
      props: ticket.pick("collaborator_ids"),
      url: "https://#{ZENDESK_HOST}/agent/tickets/#{ticket["id"]}" } }

end
