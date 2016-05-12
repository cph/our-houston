Houston::Slack.config do
  listen_for "what is for lunch {{date:relative-date}}",
             "what is for lunch on {{date:relative-date}}",
             "what is for lunch" do |e|

    e.typing
    response = Faraday.get "http://cphweb09/mycph/menu.asp"
    unless response.status == 200
      e.reply "Uh, oh. Looks like I can't get to the menu right now. :sweat_smile: Maybe you can try: http://cphweb09/mycph/menu.asp"
      next
    end

    today = Date.today
    date = e.matched?("date") ? e.match["date"] : today
    date_query = date.strftime("%A, %B %-d, %Y")
    document = Nokogiri::HTML(response.body)
    date_heading = document.at_css("i[text()=\"#{date_query}\"]")
    if date_heading.nil?
      e.reply "Hm, looks like _nothing's_ on the menu for #{date_query} :sweat:"
      next
    end

    menu_elements = date_heading.parent.next_element.children
    menu = menu_elements.select { |e| e.text? }.map { |e| "> #{e.text}" }.join("\n")
    message = date == today ? "Today's menu is:" : "The menu for #{date.strftime('%A (%-m/%-d)')} is:"
    e.reply "#{message}\n#{menu}"
  end
end
