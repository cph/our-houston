Houston::Slack.config do
  overhear(/assign (?<type>err|itsm|cve) (?<number>\d+) to (?<user>@.*\b)/i) do |e|
    alert = Houston::Alerts::Alert.find_by(type: e.match[:type], number: e.match[:number])
    unless alert
      e.reply "I'm sorry. I couldn't find an #{e.match[:type]} #{e.match[:number]}."
      next
    end

    assignee = User.find_by_slack_username(e.match[:user])
    unless assignee
      e.reply "I'm sorry. I don't know #{nickname}."
      next
    end

    alert.updated_by = e.user
    alert.checked_out_by = assignee
    unless alert.save
      e.reply "I'm sorry. I couldn't assign that alert.", *alert.errors.full_messages
      next
    end

    e.reply ":+1:"
  end

  overhear(/i['’]ll take (?<type>err|itsm|cve) (?<number>\d+)/i) do |e|
    alert = Houston::Alerts::Alert.find_by(type: e.match[:type], number: e.match[:number])
    unless alert
      e.reply "I'm sorry. I couldn't find an #{e.match[:type]} #{e.match[:number]}."
      next
    end

    unless e.user && e.user.developer?
      e.reply "I'm sorry. Only a developer can claim an alert."
      next
    end

    alert.updated_by = e.user
    alert.checked_out_by = e.user
    unless alert.save
      e.reply "I'm sorry. I couldn't assign that alert.", *alert.errors.full_messages
      next
    end

    e.reply "thanks, #{e.user.first_name}"
  end
end
