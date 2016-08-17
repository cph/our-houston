module StagingHelper

  def checkboxes(pull_request)
    counter(unchecked_checkboxes(pull_request), css: "counter-unchecked") +
    counter(checked_checkboxes(pull_request), css: "counter-checked").html_safe
  end

  def counter(count, css: "")
    "<span class=\"counter #{css} #{"zero" if count.zero?}\">#{count}</span>".html_safe
  end

  def checked_checkboxes(pull_request)
    pull_request.body.to_s.scan("[x]").count
  end

  def unchecked_checkboxes(pull_request)
    pull_request.body.to_s.scan("[ ]").count
  end

  def staging_status(pull_request)
    labels = pull_request.labels.select { |name| ['test-pass', 'test-hold'].include?(name)}
    label_out = ""
    labels.each do |label|
      label_out << "<span class=\"pr-tag #{label}\">&nbsp;</span>"
    end
    label_out.html_safe
  end

end
