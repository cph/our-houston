class ReportsMailer < ::ViewMailer
  self.stylesheets = stylesheets + %w{reports/charts.scss}

  helper Houston::ReportsHelper

  def weekly_user_report(report, options={})
    @report = report

    mail(options.pick(:cc, :bcc).merge({
      to:       options.fetch(:to, report.user),
      subject:  "#{report.username} ⭑ #{report.date.strftime("%b %-d, %Y")}",
      template: "reports/user_report"
    }))
  end

end
