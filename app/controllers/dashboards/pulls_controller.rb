module Dashboards
  class PullsController < ApplicationController
    layout "instance_dashboard"

    def index
      pulls = Github::PullRequest.open
        .preload(:project, :user)
        .without_labels("archived", "experimental")
        .order(created_at: :asc)

      @queues = {
        "On Hold" => [],
        "WIP" => [],
        "Review Needed" => [],
        "Waiting for Staging" => [],
        "In-Testing" => [],
        "Ready to Release" => []
      }
      @title = "Pull Requests (#{pulls.count})"

      pulls.each do |pull|
        if pull.labeled?("wip")
          @queues["WIP"].push pull
          next
        end

        unless pull.labeled_any?("review-pass", "review-hold")
          @queues["Review Needed"].push pull
        end

        if pull.labeled?("hold")
          @queues["On Hold"].push pull
          next
        end

        if pull.labeled?("review-pass") && pull.labeled_any?("test-pass", "no-test")
          @queues["Ready to Release"].push pull
        elsif pull.labeled?("test-needed", "on-staging")
          @queues["In-Testing"].push pull
        elsif pull.labeled?("test-needed") && !pull.labeled?("on-staging")
          @queues["Waiting for Staging"].push pull
        else
          @queues["WIP"].push pull
        end
      end

      render partial: "dashboards/pulls/pulls" if request.xhr?
    end

  end
end
