Houston.config do

  every "weekday at 12:00pm", "remind:startime" do
    today = Date.today
    first_of_month = today.beginning_of_month
    yesterday = today - 1

    date_range = first_of_month..yesterday
    dates_expected = date_range.select { |date| (1..5).include?(date.wday) }
    next if dates_expected.empty?

    EP_EMPLOYEES.each do |email|
      user = User.find_by_email_address(email)
      next unless user

      records = get_time_records_for(user, during: date_range)
      dates_missing_empower = dates_expected & records.select { |time| time[:off] < 6 && time[:worked].zero? }.map { |time| time[:date] }
      dates_missing_star = dates_expected & records.select { |time| time[:off] < 6 && time[:charged].zero? }.map { |time| time[:date] }
      next if dates_missing_empower.none? && dates_missing_star.none?

      dates_missing_both = dates_missing_empower & dates_missing_star
      dates_missing_empower_only =  dates_missing_empower - dates_missing_both
      dates_missing_star_only = dates_missing_star - dates_missing_both

      message = "#{user.slack_username}, don't forget to put in "

      format_dates = lambda do |dates|
        dates.map { |date|
          days_ago = today - date
          if days_ago == 1
            "yesterday"
          elsif days_ago <= 7
            if date.beginning_of_week < today.beginning_of_week
              "last " << date.strftime("%A")
            else
              date.strftime("%A")
            end
          else
            date.strftime("%b %-d")
          end
        }.to_sentence
      end

      if dates_missing_empower_only.none? && dates_missing_star_only.none?
        message << "your time (Star & Empower) for #{format_dates.(dates_missing_both)}"
      elsif dates_missing_both.any? && dates_missing_empower_only.any? && dates_missing_star_only.any?
        message << "your Star time for #{format_dates.(dates_missing_star_only)}, "
        message << "your Empower time for #{format_dates.(dates_missing_empower_only)}, and "
        message << "both for #{format_dates.(dates_missing_both)}"
      else
        missing = []
        missing << "your Star time for #{format_dates.(dates_missing_star_only)}" if dates_missing_star_only.any?
        missing << "your Empower time for #{format_dates.(dates_missing_empower_only)}" if dates_missing_empower_only.any?
        missing << "both your Star and Empower time for #{format_dates.(dates_missing_both)}" if dates_missing_both.any?
        message << missing.to_sentence
      end

      slack_send_message_to message, "developers-only"
    end
  end

end
