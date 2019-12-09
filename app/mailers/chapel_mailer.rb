class ChapelMailer < ::ViewMailer

  def summary(service, options={})
    @service = service
    recipients = Team.find_by(name: "Chapel")
      .users
      .where("ARRAY['Maintainer', 'Tester'] && teams_users.roles::text[]")
    mail(options.pick(:cc, :bcc).merge({
      to:       options.fetch(:to, recipients),
      subject:  "Chapel Service on #{service.date.strftime("%B %-d, %Y")}",
      template: "chapel_services/service_summary"
    }))
  end

end
