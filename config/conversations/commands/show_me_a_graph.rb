Houston::Conversations.config do
  overhear "show me a graph" do |e|
    a_graph = MeasurementGraphOptions.new(
      measurements: %w{daily.requests.duration.mean},
      projects: "members",
      start_time: 3.months.ago)

    e.reply nil,
      attachments: [{
        fallback: "[A graph of Members' mean response time for the last 3 months]",
        text: "Members' mean response time for the last 3 months",
        image_url: a_graph.to_url
      }]
  end
end
