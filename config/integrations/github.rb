# Configuration for GitHub
# Use the following command to generate an access_token
# for your GitHub account to allow Houston to modify
# commit statuses.
#
# curl -v -u USERNAME -X POST https://api.github.com/authorizations --data '{"scopes":["repo:status"]}'
#
Houston.config.github do
  # Access token for houstonbot with scopes: ["repo"]
  access_token ENV["HOUSTON_GITHUB_ACCESS_TOKEN"]
  key ENV["HOUSTON_GITHUB_KEY"]
  secret ENV["HOUSTON_GITHUB_SECRET"]
  organization "cph"
end


# Configure the Github Issues TicketTracker adapter
Houston.config.ticket_tracker :github do
  identify_type lambda { |ticket|
    labels = Array(ticket.raw_attributes["labels"]).map { |label| label["name"].downcase }
    return "Bug"      if (labels & %w{bug}).any?
    return "Feature"  if (labels & %w{feature}).any?
    return "Enhancement" if (labels & %w{enhancement tweak}).any?
    return "Chore"    if (labels & %w{chore refactor}).any?
    "Enhancement"
  }

  attributes_from_type lambda { |type|
    case type
    when "Enhancement" then {labels: ["enhancement"]}
    when "Bug" then {labels: ["bug"]}
    when "Feature" then {labels: ["feature"]}
    when "Chore" then {labels: ["chore"]}
    else {}
    end
  }

  identify_tags lambda { |ticket|
    Array(ticket.raw_attributes["labels"]) \
      .select { |label| !%w{bug feature enhancement refactor chore}.member?(label["name"].downcase) } \
      .map { |label| TicketTag.new(label["name"], label["color"]) }
  }
end
