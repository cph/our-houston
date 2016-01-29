Houston::Slack.config do
  slash("esv") do |e|
    if e.text.blank?
      # Print usage
      e.respond! "No search query given. Usage: `/esv <reference>` where reference is a verse reference, e.g. John 3:16 (book abbreviations _are_ supported)."
    else
      connection = Faraday.new(url: "http://www.esvapi.org")
      query = "/v2/rest/passageQuery?#{build_query_with_reference(e.text)}"
      response = connection.get(query)

      if response.status != 200
        e.respond! "It looks like ESV is not available at the moment. :sweat:"
      else
        e.respond! response.body
      end
    end
  end
end

def build_query_with_reference(reference)
  params = esv_params.merge(passage: CGI::escape(reference))
  params.map { |key, value| "#{key}=#{value}" }.join("&")
end

def esv_params
  { key: "IP",
    "output-format" => "plain-text",
    "include-footnotes" => false,
    "include-passage-horizontal-lines" => false,
    "include-heading-horizontal-lines" => false,
    "include-headings" => false,
    "include-subheadings" => false,
    "line-length" => 0 }
end
