class KpiSurveyComment

  def self.since(date)
    client = TinyTds::Client.new(
      username: ENV["HOUSTON_BACKOFFICE_USERNAME"],
      password: ENV["HOUSTON_BACKOFFICE_PASSWORD"],
      host: "10.5.3.25", # cphsql004
      tds_version: "7.3") # SQL Server 2008

    client.execute(<<-SQL).each(symbolize_keys: true).to_a
      select
        CPH_Survey.dbo.SurveyEventQuestions.EventQuestionID,
        CPH_Survey.dbo.SurveyQuestions.QuestionText,
        coalesce(nullif(CPH_Survey.dbo.SurveyEventQuestions.TextOnlyAnswer, ''),CPH_Survey.dbo.SurveyEventQuestions.AnswerComment) AS "Text",
        CPH_Survey.dbo.SurveyEvents.EmailAddress,
        CPH_Survey.dbo.SurveyEvents.DateSurveyTaken
      from CPH_Survey.dbo.SurveyEventQuestions
      inner join CPH_Survey.dbo.SurveyQuestions on CPH_Survey.dbo.SurveyQuestions.QuestionID=CPH_Survey.dbo.SurveyEventQuestions.QuestionID
      inner join CPH_Survey.dbo.SurveyEvents on CPH_Survey.dbo.SurveyEvents.EventID=CPH_Survey.dbo.SurveyEventQuestions.EventID
      where CPH_Survey.dbo.SurveyEvents.DateSurveyTaken >= '#{date.iso8601}'
      and coalesce(nullif(CPH_Survey.dbo.SurveyEventQuestions.TextOnlyAnswer, ''),CPH_Survey.dbo.SurveyEventQuestions.AnswerComment) != '';
    SQL
  ensure
    client.close if client
  end

  def self.import_since!(date)
    import! since(date)
  end

  def self.import!(comments)
    ids = comments.map { |comment| comment[:EventQuestionID].to_s }
    already_imported_ids = Houston::Feedback::Comment.where(legacy_id: ids).pluck(:legacy_id)
    to_import = comments.reject { |comment| already_imported_ids.member?(comment[:EventQuestionID].to_s) }
    project = Project["kpi-survey"]

    comments = to_import.map do |comment|
      Houston::Feedback::Comment.new(
        project: project,
        text: "###### #{comment[:QuestionText]}\n\n#{comment[:Text]}",
        attributed_to: comment[:EmailAddress],
        legacy_id: comment[:EventQuestionID],
        created_at: comment[:DateSurveyTaken]).tap do |comment|
        comment.update_plain_text # because the import command won't
      end
    end

    Houston::Feedback::Comment.import(comments).tap do
      Houston::Feedback::Comment.for_project(project).reindex!
    end
  end

end
