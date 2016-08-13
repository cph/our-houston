Houston.config.at [:weekday, "6:40am"], "report:alerts" do
  next if Rails.env.development?
  Houston::Alerts::Mailer.deliver_to!(EP_DEVELOPERS)
end
