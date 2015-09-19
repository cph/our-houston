Houston.config do
  on "github:pull:updated" do |pull_request, changes|
    next unless changes.key? "labels"
    before, after = changes["labels"]
    before = before.split("\n")

    removed = before - after
    added = after - before
    if (before.include?("on-staging") && added.include?("test-pass")) || removed.include?("on-staging")
      Houston.observer.fire "staging:#{pull_request.project.slug}:free"
    end
  end
end
