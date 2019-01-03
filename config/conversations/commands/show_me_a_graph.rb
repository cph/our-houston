module GraphHelper
  def graph(options={})
    description = options.fetch(:description)

    if matched?(:duration)
      options[:start_time] = match[:duration].before(Date.today).to_time
      description << " for the last #{match[:duration]}"
    end

    if matched?(:start)
      options[:start_time] = match[:start].to_time
      description << " since #{match[:start]}"
    end

    reply nil, attachments: [{
      fallback: "[A graph of #{options.fetch(:description)}]",
      text: description,
      image_url: MeasurementGraphOptions.new(options.except(:description)).to_url
    }]
  end
end


Houston::Conversations.config do
  [ %w{members members'},
    %w{unite unite's},
    %w{ledger ledger's},
    %w{lsb lsb's},
    %w{builder builder's},
  ].each do |(project, possessive)|
    project = "lsb" if project == "builder"

    [
      [ ["mean response time", "response time", "average response time"],
        { measurements: %w{daily.requests.duration.mean} } ],

      [ ["error rate"],
        { measurements: %w{daily.requests daily.requests.5*}, transform: "percent", format: ".3f" } ]

    ].each do |(values, options)|
      values.each do |value|
        listen_for "show me #{possessive} #{value} for the last {{duration:core.date.duration}}",
                   "show me #{possessive} #{value} since {{start:core.date.past}}",
                   "show me #{possessive} #{value}" do |e|
          e.extend GraphHelper
          e.graph options.merge(description: "#{possessive.capitalize} #{values[0]}", projects: project)
        end
      end
    end
  end

  listen_for "show me our alerts closure rate for the last {{duration:core.date.duration}}",
             "show me our alerts closure rate since {{start:core.date.past}}",
             "show me our alerts closure rate" do |e|
     e.extend GraphHelper
     e.graph measurements: %w{daily.alerts.due daily.alerts.due.completed-on-time},
             description: "Percent of Alerts closed on-time",
             transform: "percent-cumulative",
             format: "d",
             min: 70,
             max: 100
  end

end
