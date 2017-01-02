module GraphHelper
  def graph(options={})
    description = options.fetch(:description)

    if matched?(:duration)
      options[:start_time] = match[:duration].before(Date.today).to_time
      description << " for the last #{match[:duration]}"
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
    %w{ledger ledger's}
  ].each do |(project, possessive)|
    [
      [ ["mean response time", "response time", "average response time"],
        { measurements: %w{daily.requests.duration.mean} } ],

      [ ["error rate"],
        { measurements: %w{daily.requests daily.requests.5*}, transform: "percent", format: ".3f" } ]

    ].each do |(values, options)|
      values.each do |value|
        listen_for "show me #{possessive} #{value} for the last {{duration:core.date.duration}}",
                   "show me #{possessive} #{value}" do |e|
          e.extend GraphHelper
          e.graph options.merge(description: "#{possessive.capitalize} #{values[0]}", projects: project)
        end
      end
    end
  end
end
