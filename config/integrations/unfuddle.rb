# Configure the Unfuddle TicketTracker adapter
Houston.config.ticket_tracker :unfuddle do
  subdomain "cphep"
  username ENV["HOUSTON_UNFUDDLE_USERNAME"]
  password ENV["HOUSTON_UNFUDDLE_PASSWORD"]

  identify_tags lambda { |ticket|
    tags = []
    tags << TICKET_TAGS_FOR_UNFUDDLE[ticket.severity]
    tags << TicketTag.new(ticket.component, "404040") unless ticket.component.blank?
    tags.compact
  }

  identify_type lambda { |ticket|
    case ticket.severity
    when "0 Suggestion" then ticket.summary =~ /New Feature/ ? "Feature" : "Enhancement"
    when "Feature", "Bug", "Chore", "Enhancement" then ticket.severity
    else "Enhancement"
    end
  }

  attributes_from_type lambda { |type|
    severity = type
    severity = "Enhancement" if severity == "Tweak"
    {severity: severity}
  }
end

TICKET_TAGS_FOR_UNFUDDLE = {
  nil                             => nil,
  "0 Suggestion"                  => "[Suggestion](0088CC)",
  "D Development"                 => nil,
  "R Refactor"                    => "[Refactor](98C221)",
  "1 Lack of Polish"              => "[Lack of Polish](ACC042)",
  "1 Visual Bug"                  => nil,
  "P Performance"                 => "[Performance](ACC042)",
  "2 Confusing to Users"          => "[Confusing](E9A43F)",
  "3 Design Flaw"                 => "[Spec Flaw](E9A43F)",
  "4 Broken (with work-around)"   => nil,
  "S Security Hole"               => "[Security](D65B17)",
  "5 Broken (no work-around)"     => "[No Work-Around](C1311E)"
}
