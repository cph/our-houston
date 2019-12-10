class ChapelMailer < ::ViewMailer

  def summary(service, options={})
    @service = service
    recipients = Team.find_by(name: "Chapel")
      .users
      .where("'Maintainer' = ANY(teams_users.roles)")
    mail(options.pick(:cc, :bcc).merge({
      to:       options.fetch(:to, recipients),
      subject:  "Chapel Service on #{service.date.strftime("%b %-d, %Y")}",
      template: "reports/user_report"
    }))
  end

end
