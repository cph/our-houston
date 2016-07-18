Houston.config.at [:weekday, "6:40am"], "report:alerts" do
  Houston.try({max_tries: 3}, Net::OpenTimeout) do
    Houston::Alerts::Mailer.deliver_to!(EP_DEVELOPERS) unless Rails.env.development?
  end
end
