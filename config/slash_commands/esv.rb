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
      query = "/v2/rest/passageQuery", esv_params.merge(passage: CGI::escape(e.text))
      response = connection.get(query)

      if response.status != 200
        e.respond! "It looks like ESV is not available at the moment. :sweat:"
      else
        styled = response.body.sub(/(.*)$/,"*\\1*")
        e.respond! styled
      end
    end
  end
end
