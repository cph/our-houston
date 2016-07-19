Houston.config do
  on "github:pull:updated" => "github:fire-events-for-label-changes" do
    next unless changes.key? "json_labels"
    before, after = changes["json_labels"]
    before = before.map { |label| label["name"] }
    after = after.map { |label| label["name"] }

    removed = before - after
    added = after - before

    removed.each do |label|
      Houston.observer.fire "github:pull:label-removed", pull_request: pull_request, label: label
    end

    added.each do |label|
      Houston.observer.fire "github:pull:label-added", pull_request: pull_request, label: label
    end

    if (before.include?("on-staging") && added.include?("test-pass")) || removed.include?("on-staging")
      Houston.observer.fire "staging:#{pull_request.project.slug}:free"
    end
  end
end
