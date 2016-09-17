Houston::Conversations.config do
  listen_for "what is for lunch {{date:core.date.future}}",
             "what is for lunch on {{date:core.date.future}}",
             "what is for lunch" do |e|

    e.responding
    today = Date.today
    date = e.matched?("date") ? e.match["date"] : today

    begin
      menu_items = LunchMenu.for date
    rescue Faraday::HTTP::Error
      e.reply "Uh, oh. Looks like I can't get to the menu right now. :sweat_smile: Maybe you can try: http://cphweb09/mycph/menu.asp"
      next
    end

    unless menu_items
      e.reply "Hm, looks like _nothing's_ on the menu for #{date_query} :sweat:"
      next
    end

    message = date == today ? "Today's menu is:" : "The menu for #{date.strftime('%A (%-m/%-d)')} is:"
    e.reply "#{message}\n#{menu_items.map { |item| "> #{item}" }.join("\n")}"
  end
end
