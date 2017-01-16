module PullRequestsHelper

  def pull_request_label(label)
    background = "##{label["color"]}"
    foreground = "#fff"
    foreground = "#333" if %w{#f7c6c7 #d4c5f9 #fbca04 #fad8c7 #bfe5bf}.member? background
    "<span class=\"label\" style=\"background: #{background}; color: #{foreground};\">#{label["name"]}</span>".html_safe
  end

end
