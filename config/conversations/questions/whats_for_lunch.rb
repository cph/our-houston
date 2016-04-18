Houston::Slack.config do
  MENU_URL = "http://cphweb09/mycph/menu.asp".freeze

  listen_for(/what'?s for lunch(?:\s(?:on\s)?(?<next>next\s)?(?<day>\w+))?/i) do |e|
    today = Date.today

    next_wday = lambda do |wday|
      days_until_wday = wday - today.wday
      days_until_wday += 7 if days_until_wday < 0
      today + days_until_wday
    end

    date = case e.match[:day]
    when /tomorrow/ then today + 1
    when /^mon/ then next_wday[1]
    when /^tue/ then next_wday[2]
    when /^wed/ then next_wday[3]
    when /^thu/ then next_wday[4]
    when /^fri/ then next_wday[5]
    else; today
    end

    date += 7 if e.matched? :next

    response = Faraday.get MENU_URL
    unless response.status == 200
      e.reply "Uh, oh. Looks like I can't get to the menu right now. :sweat_smile: Maybe you can try: http://cphweb09/mycph/menu.asp"
      next
    end

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
