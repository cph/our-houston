def ep_developer?(user)
  user && EP_DEVELOPERS.member?(user.email)
end

TODOIST_ALERTS_PROJECT_ID = Rails.env.production? ? 200021224 : 200357697
TODOIST_ITEM_ID = "todoist.itemId".freeze
TODOIST_TEAM_IDS = [10, 1, 3, 8, 7, 12, 6, 11].freeze

def sync_open_alerts_to_todoist
  items = todoist_send("projects/get_data", project_id: TODOIST_ALERTS_PROJECT_ID).fetch "items"
  alerts = Houston::Alerts::Alert.where(project_id: Team.where(id: TODOIST_TEAM_IDS).project_ids)

  item_ids = items.map { |item| item["id"] }
  expected_item_ids = alerts.open.pluck("props->'todoist.itemId'")
  unexpected_item_ids = item_ids - expected_item_ids

  unexpected_item_ids.each do |item_id|
    alert = alerts.unscope(where: [:destroyed_at, :suppressed]).find_by_prop(TODOIST_ITEM_ID, item_id)
    if alert.nil?
      Rails.logger.info "[todoist:sync] An Alert mapped to Item ##{item_id} does not exist"
      todoist_send_command "item_delete", ids: [item_id]
    elsif alert.destroyed?
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} mapped to Item ##{item_id} has been destroyed"
      todoist_send_command "item_delete", ids: [item_id]
    elsif alert.suppressed?
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} mapped to Item ##{item_id} has been suppressed"
      todoist_send_command "item_delete", ids: [item_id]
    elsif alert.closed?
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} mapped to Item ##{item_id} has been closed"
      todoist_send_command "item_close", ids: [item_id]
    else
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} is not destroyed, suppressed, or closed"
    end
  end

  alerts.open.each do |alert|
    sync_alert_to_todoist alert
  end

  :ok
end

def sync_alert_to_todoist(alert)
  return unless Team.where(id: TODOIST_TEAM_IDS).project_ids.member?(alert.project_id)
  alert.with_lock do
    item_id = alert.props[TODOIST_ITEM_ID]
    if item_id
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} mapped to Item ##{item_id} has changed, checking whether the Item should be updated..."
      update_todoist_alert(alert, item_id)
    else
      Rails.logger.info "[todoist:sync] Alert ##{alert.number} is not mapped to an Item, creating one..."
      create_todoist_alert(alert)
    end
  end
end

def update_todoist_alert(alert, item_id)
  due_date = alert.deadline.utc.strftime("%Y-%m-%dT%H:%M")
  project_slug = alert.project&.slug || "unknown"
  content = "**#{alert.number}** | **#{project_slug}** | #{alert.summary}"

  raise ArgumentError, "Expected item_id #{item_id.inspect} to be an Integer" unless item_id.is_a?(Integer)

  item = begin
    todoist_send("items/get", item_id: item_id, all_data: false).fetch "item"
  rescue Faraday::ResourceNotFound
    alert.update_prop! TODOIST_ITEM_ID, nil
    return create_todoist_alert(alert)
  end
  item_due_date = Time.parse(item["due_date_utc"]).strftime("%Y-%m-%dT%H:%M")

  if content != item["content"] || due_date != item_due_date
    todoist_send_command "item_update", {
      id: item_id,
      content: content,
      date_string: due_date,
      due_date_utc: due_date }
  end

  if alert.suppressed? || alert.destroyed?
    todoist_send_command "item_delete", ids: [item_id]
  end

  if alert.closed? && item["checked"] == 0
    todoist_send_command "item_complete", ids: [item_id]
  end

  if alert.open? && item["checked"] == 1
    todoist_send_command "item_uncomplete", ids: [item_id]
  end

rescue
  $!.additional_information["alert.number"] = alert.number
  raise
end

def create_todoist_alert(alert)
  return unless alert.open?

  connection = Faraday.new(url: "https://todoist.com/API/v7")
  connection.use Faraday::RaiseErrors
  token = ENV["HOUSTON_TODOIST_ACCESS_TOKEN"]
  due_date = alert.deadline.utc.strftime("%Y-%m-%dT%H:%M")
  project_slug = alert.project&.slug || "unknown"
  content = "**#{alert.number}** | **#{project_slug}** | #{alert.summary}"
  id = SecureRandom.uuid

  json = todoist_send_commands [{
      type: "item_add",
      temp_id: id,
      uuid: SecureRandom.uuid,
      args: {
        project_id: TODOIST_ALERTS_PROJECT_ID,
        content: content,
        date_string: due_date,
        due_date_utc: due_date } }]

  race_id = alert.reload.props[TODOIST_ITEM_ID]
  if race_id.is_a?(Integer)
    raise "Alert #{alert.number} has already been associated with Todoist Item #{race_id}"
  end

  alert.update_prop! TODOIST_ITEM_ID, json.fetch("temp_id_mapping").fetch(id)

rescue
  $!.additional_information["item_add.response"] = json
  $!.additional_information["alert.number"] = alert.number
  raise
end

def todoist_delete_item(*ids)
  todoist_send_command "item_delete", ids: ids
end

def todoist_send_command(type, args={})
  todoist_send_commands [{ type: type, uuid: SecureRandom.uuid, args: args }]
end

def todoist_send_commands(commands)
  todoist_send("sync", commands: MultiJson.dump(commands))
end

def todoist_send(path, params={})
  token = ENV["HOUSTON_TODOIST_ACCESS_TOKEN"]
  MultiJson.load(todoist_connection.post(path, params.merge(token: token)).body)
end

def todoist_connection
  @connection ||= Faraday.new(url: "https://todoist.com/API/v7").tap do |connection|
    connection.use Faraday::RaiseErrors
  end
end
