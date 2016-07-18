Houston.config.at [:weekday, "11:00am"], "announce:menu" do
  response = Faraday.get "http://cphweb09/mycph/menu.asp"
  next unless response.status == 200

  today = Date.today
  date_query = today.strftime("%A, %B %-d, %Y")
  document = Nokogiri::HTML(response.body)
  date_heading = document.at_css("i[text()=\"#{date_query}\"]")
  next if date_heading.nil?

  menu_elements = date_heading.parent.next_element.children
  menu = menu_elements.select { |e| e.text? }.map { |e| "> #{e.text}" }.join("\n")
  slack_send_message_to "Today's menu is:\n#{menu}", "#general"
end
