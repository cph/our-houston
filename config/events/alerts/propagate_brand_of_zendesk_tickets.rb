Houston.config do
  # Notify Zendesk of change of brand
  on "alert:zendesk:update" => "alert:propagate-brand-to-zendesk" do
    next unless alert.saved_change_to_project_id?

    if ZENDESK_BRANDS.empty?
      response = MultiJson.load($zendesk.get("brands").body)
      response["brands"].each do |brand|
        ZENDESK_BRANDS[brand["id"]] = ZENDESK_BRAND_PROJECT_MAP.fetch(brand["subdomain"], brand["subdomain"])
      end
    end

    brand_id = ZENDESK_BRANDS.key(alert.project.slug) if alert.project
    next unless brand_id

    $zendesk.put "tickets/#{alert.number}",
      MultiJson.dump(ticket: {brand_id: brand_id}),
      "Content-Type" => "application/json"
  end
end
