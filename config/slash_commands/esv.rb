Houston::Slack.config do
  slash("esv") do |e|
    if e.text.blank?
      # Print usage
      e.respond! "Hm, looks like you forgot the scripture reference.\nUse `/esv <reference>` to look up a scripture reference.\nExamples:\n* `/esv John 3:16`\n* `/esv Mt 1`\n(Yep, book abbreviations _are_ supported)"
    else
      esv_params = { key: "IP",
                     "output-format" => "plain-text",
                     "include-footnotes" => false,
                     "include-passage-horizontal-lines" => false,
                     "include-heading-horizontal-lines" => false,
                     "include-headings" => false,
                     "include-subheadings" => false,
                     "line-length" => 0 }

      connection = Faraday.new(url: "http://www.esvapi.org")
      query = "/v2/rest/passageQuery"
      passage = e.text.split(/ /).join("+")
      response = connection.get query, esv_params.merge(passage: passage)

      if response.status != 200
        e.respond! "It looks like ESV is not available at the moment. :sweat:"
      else
        title, text = response.body.split(/\n/, 2)
        text.gsub!(/(\[[0-9\:]+\])/, "*\\1* ")         # Bold verse markers

        e.respond!(
          response_type: "in_channel",
          attachments: [{
            fallback: "#{title} (ESV)",
            title: "#{title} (ESV)",
            title_link: "http://esvbible.org/#{passage}",
            text: text,
            mrkdwn_in: ["text"] }])
      end
    end
  end
end
