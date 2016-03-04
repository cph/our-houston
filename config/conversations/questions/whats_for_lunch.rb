Houston::Slack.config do
  listen_for(/what.*s for lunch(?:\s(?:on\s)?(?<modifier>next\s)?(?<day>.*))?\??/i) do |e|
    day = e.match[:day] || "today"
    day = day.downcase.gsub(/\?/, "")
    day = "today" unless day =~ /^(?:mon|tues|wed(?:nes)?|thu(?:rs)?|fri)(?:day)?$|^tomorrow$/

    target_date = Date.today
    target_date += 1.day if day == "tomorrow"
    unless day =~ /today|tomorrow/
      find_next_week = !e.match[:modifier].nil?
      target_wday = case day
      when /mon/ then 1
      when /tue/ then 2
      when /wed/ then 3
      when /thu/ then 4
      when /fri/ then 5
      end
      today_wday = target_date.wday
      if today_wday > target_wday
        day_diff = 7 - (today_wday - target_wday)
        target_date += day_diff.days
      elsif today_wday == target_wday && find_next_week
        target_date += 7.days
      else
        day_diff = target_wday - today_wday
        target_date += day_diff.days
      end
    end

    connection = Faraday.new(url: "http://cphweb09")
    response = connection.get "/mycph.menu.asp"

    http = Net::HTTP.new "cphweb09", 80
    request = Net::HTTP::Get.new '/mycph/menu.asp'
    response = http.request request

    snark = [
      "Alright, here's what I found:",
      "Your need for daily nutrition is so quaint:",
      "Definitely glad _I_ don't have to eat human food #{target_date.strftime('%A')}",
      "The menu for #{target_date.strftime('%A')} is:",
      "Mmmm... :yum:",
      "Some days I wish I _didn't_ run on pure science:",
      "Get it while it's hot!"
    ]
    menu_snark = snark[rand(0...snark.count)]

    if response.code != "200"
      e.reply "Uh, oh. Looks like I can't get to the menu right now. :sweat_smile: Maybe you can try: http://cphweb09/mycph/menu.asp"
    else
      date_query = target_date.strftime("%A, %B %-d, %Y")
      document = Nokogiri::HTML(response.body)
      date_heading = document.at_css("i[text()=\"#{date_query}\"]")
      if date_heading.nil?
        e.reply "Hm, looks like _nothing's_ on the menu for #{date_query} :sweat:"
      else
        menu_elements = date_heading.parent.next_element.children
        menu = menu_elements.select { |e| e.text? }.map { |e| "> #{e.text}" }.join("\n")
        e.reply "#{menu_snark}\n#{menu}"
      end
    end
  end
end
