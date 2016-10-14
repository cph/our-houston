Houston.config.on "hooks:kpi-survey-comments" => "record-kpi-survey-comments" do
  comments = params[:comments]
  ids = comments.map { |comment| comment["EventQuestionID"].to_s }
  already_imported_ids = Houston::Feedback::Conversation.where(legacy_id: ids).pluck(:legacy_id)
  to_import = comments.reject { |comment| already_imported_ids.member?(comment["EventQuestionID"].to_s) }

  project = Project["kpi-survey-private"]
  comments = to_import.map do |comment|
    Houston::Feedback::Conversation.new(
      project: project,
      import: Time.now.iso8601,
      text: "###### #{comment["QuestionText"]}\n\n#{comment["Text"]}",
      attributed_to: comment["EmailAddress"],
      legacy_id: comment["EventQuestionID"],
      created_at: comment["DateSurveyTaken"]).tap do |comment|
      comment.update_plain_text # because the import command won't
    end
  end

  Houston::Feedback::Conversation.import(comments).tap do
    Houston::Feedback::Conversation.for_project(project).reindex!
  end
end
