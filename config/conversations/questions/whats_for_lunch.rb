require_relative "../../../lib/side_project/base"
require "net/https"

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
      when /mon/
        1
      when /tue/
        2
      when /wed/
        3
      when /thu/
        4
      when /fri/
        5
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

    e.reply "Hold on, I'll check..."

    Houston.side_projects.start! Houston::SideProject::Lunch.new(
      user: e.user,
      conversation: e.start_conversation!,
      date: target_date)
  end
end

module Houston
  module SideProject
    class Lunch < Base
      attr_reader :date

      FULLDATE = "%A, %B %-d, %Y"

      def initialize(attributes)
        @date = attributes.fetch :date
        super attributes.merge(description: "I'm looking up what's for lunch on #{date.strftime(FULLDATE)}.")
      end

      def start!
        fetch_lunch_menu
      end

      def fetch_lunch_menu
        http = Net::HTTP.new "cphweb09", 80
        request = Net::HTTP::Get.new '/mycph/menu.asp'
        response = http.request request

        if response.code != "200"
          end! "Uh, oh. Looks like I can't get to the menu right now. :sweat_smile: Maybe you can try: http://cphweb09/mycph/menu.asp"
        else
          date_query = date.strftime(FULLDATE)
          document = Nokogiri::HTML(response.body)
          date_heading = document.at_css("i[text()=\"#{date_query}\"]")
          if date_heading.nil?
            end! "Hm, looks like _nothing's_ on the menu for #{date_query} :sweat:"
          else
            menu_elements = date_heading.parent.next_element.children
            menu = menu_elements.select { |e| e.text? }.map { |e| "> #{e.text}" }.join("\n")
            end! "#{menu_snark}\n#{menu}"
          end
        end
      end

      def menu_snark
        snark = [
          "Alright, here's what I found:",
          "Aww, your need for daily nutrition is so quaint :wink:",
          "Yep, definitely glad _I_ don't have to eat human food #{date.strftime('%A')}",
          "The menu for #{date.strftime('%A')} is:",
          "Nom, nom, nom :yum:",
          "Mmmm... :yum:",
          "Man, some days I wish I _didn't_ run on pure science",
          "Finger-lickin' good! (Or so I've been told) :sweat_smile:",
          "Get it while it's hot!"
        ]
        snark[rand(0...snark.count)]
      end
    end
  end
end
