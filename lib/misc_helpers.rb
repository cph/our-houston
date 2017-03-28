def ep_developer?(user)
  user && EP_DEVELOPERS.member?(user.email)
end

TODOIST_ALERTS_PROJECT_ID = Rails.env.production? ? 200021224 : 200357697
TODOIST_ITEM_ID = "todoist.itemId".freeze

def sync_alert_to_todoist(alert)
  connection = Faraday.new(url: "https://todoist.com/API/v7")
  connection.use Faraday::RaiseErrors
  token = ENV["HOUSTON_TODOIST_ACCESS_TOKEN"]
  due_date = alert.deadline.utc.strftime("%Y-%m-%dT%H:%M")
  id = alert.props[TODOIST_ITEM_ID]

  if id
    response = connection.post("items/get", token: token, item_id: id, all_data: false)
    item = MultiJson.load(response.body).fetch "item"

    if alert.summary != item["content"] || due_date != item["due_date_utc"]
      connection.post("sync",
        token: token,
        commands:  MultiJson.dump([{
          type: "item_update",
          uuid: SecureRandom.uuid,
          args: {
            id: id,
            content: alert.summary,
            date_string: due_date,
            due_date_utc: due_date }
        }]))
    end

    if alert.closed? && item["checked"] == 0
      connection.post("sync",
        token: token,
        commands:  MultiJson.dump([{
          type: "item_complete",
          uuid: SecureRandom.uuid,
          args: { ids: [id] }
        }]))
    end

    if alert.open? && item["checked"] == 1
      connection.post("sync",
        token: token,
        commands:  MultiJson.dump([{
          type: "item_uncomplete",
          uuid: SecureRandom.uuid,
          args: { ids: [id] }
        }]))
    end

  elsif alert.open?
    temp_id = SecureRandom.uuid
    response = connection.post("sync",
      token: token,
      commands:  MultiJson.dump([{
        type: "item_add",
        temp_id: temp_id,
        uuid: SecureRandom.uuid,
        args: {
          project_id: TODOIST_ALERTS_PROJECT_ID,
          content: alert.summary,
          date_string: due_date,
          due_date_utc: due_date }
      }]))

    json = MultiJson.load(response.body)
    alert.update_prop! TODOIST_ITEM_ID, json.fetch("temp_id_mapping").fetch(temp_id)
  end
end
