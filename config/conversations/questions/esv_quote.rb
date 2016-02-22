Houston::Slack.config do
  listen_for(/(?:can\syou\s|could\syou\s)?(?:please\s)?(?<verb>quote)\s(?:to\s)?(?:me\s)?(?<reference>.*?)\??$/i) do |e|
    return if e.match[:reference].nil?

    verb = e.match[:verb].to_sym
    formats = { quote: "plain-text" } # Will allow for other formats in the future, like mp3

    esv_params = { key: "IP",
                   "output-format" => formats[verb] }

    plain_text = { "include-footnotes" => false,
                   "include-passage-horizontal-lines" => false,
                   "include-heading-horizontal-lines" => false,
                   "include-headings" => false,
                   "include-subheadings" => false,
                   "line-length" => 0
    }

    passage = e.match[:reference].split(/ /).join("+")
    params = esv_params.merge(passage: passage)
    params.merge!(plain_text) if verb == :quote

    connection = Faraday.new(url: "http://www.esvapi.org")
    query = "/v2/rest/passageQuery"
    response = connection.get query, params

    if response.status != 200
      e.reply "It looks like ESV is not available at the moment. :sweat:"
    # elsif response.status == 302 # Requesting MP3 gives a 302 with the url in the body
    #   e.reply "Here's the audio for #{e.match[:reference]}: #{response.body}"
    else
      title, text = response.body.split(/\n/, 2)
      text.gsub!(/(\[[0-9\:]+\])/, "*\\1* ")         # Bold verse markers

      e.reply "",
        attachments: [{
          fallback: "#{title} (ESV)",
          title: "#{title} (ESV)",
          title_link: "http://esvbible.org/#{passage}",
          text: text,
          color: "#B40404",
          mrkdwn_in: ["text"]
        }]
    end
  end
end
