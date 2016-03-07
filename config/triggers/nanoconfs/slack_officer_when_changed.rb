Houston.config do
  on "nanoconf:create" do |presentation|
    presentation_url = "http://#{Houston.config.host}/nanoconfs/#{presentation.id}"
    presentation_date = presentation.date.strftime("%B %d")

    message = "#{presentation.presenter.slack_username} created a new nanoconf "
    message << slack_link_to("#{presentation.title}", presentation_url)
    message << " on #{presentation_date}"

    slack_send_message_to message, User.find_by(email: "chase.clettenberg@cph.org")
  end

  on "nanoconf:update" do |presentation|
    presentation_url = "http://#{Houston.config.host}/nanoconfs/#{presentation.id}"
    presentation_date = presentation.date.strftime("%B %d")

    message = "#{presentation.presenter.slack_username} updated nanoconf "
    message << slack_link_to("#{presentation.title}", presentation_url)
    message << " on #{presentation_date}"

    slack_send_message_to message, User.find_by(email: "chase.clettenberg@cph.org")
  end
end
