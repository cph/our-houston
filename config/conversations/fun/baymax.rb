Houston::Conversations.config do
  overhear "ouch" do |e|
    e.reply "On a scale of 1 to 10, how would you rate your pain?",
      attachments: [{
        fallback: "On a scale of 1 to 10, how would you rate your pain?",
        image_url: "#{Houston.root_url}/extras/pain.png"
      }]
  end

  listen_for("hurry up") { |e| e.reply "I am not fast" }
  listen_for("fist bump") { |e| e.reply [":fist:", "ba da lata lata la"] }
end
