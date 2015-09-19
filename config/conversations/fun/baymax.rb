Houston::Slack.config do
  overhear(/\bouch\b/i) do |e|
    e.reply "On a scale of 1 to 10, how would you rate your pain?",
      attachments: [{
        fallback: "On a scale of 1 to 10, how would you rate your pain?",
        image_url: "http://status.cphepdev.com/extras/pain.png"
      }]
  end

  listen_for(/hurry up/i) { |e| e.reply "I am not fast" }
  listen_for(/fist bump/i) { |e| e.reply ":fist:", "ba da lata lata la" }
end
