Houston.config.every "weekday at 9:45am", "announce:menu" do
  menu_items = LunchMenu.for Date.today
  next unless menu_items

  message = "Today's menu is:\n#{menu_items.map { |item| "> #{item}" }.join("\n")}"
  slack_send_message_to message, "#general"
end
