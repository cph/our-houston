Houston.config.on "hooks:kpi-survey-comments" => "record-kpi-survey-comments" do
  comments = Array(params.with_indifferent_access["comments"])
  ids = comments.map { |comment| comment["EventQuestionID"].to_s }
  already_imported_ids = Houston::Feedback::Conversation.where(legacy_id: ids).pluck(:legacy_id)
  to_import = comments.reject { |comment| already_imported_ids.member?(comment["EventQuestionID"].to_s) }

  project = Project["kpi-survey-private"]
  import = Time.now.iso8601
  to_import.each do |comment|
    Houston::Feedback::Conversation.create!(
      project: project,
      import: import,
      text: comment["Text"],
      attributed_to: comment["EmailAddress"],
      legacy_id: comment["EventQuestionID"],
      created_at: comment["DateSurveyTaken"])
  end
end
