module Dashboards
  class ReleasesController < ApplicationController
    layout "instance_dashboard"
    helper_method :recent_changes, :upcoming_changes

    def index
      @title = "Releases"
    end

    def upcoming
      @title ="Upcoming"
      render partial: "dashboards/releases/changes", locals: {changes: upcoming_changes} if request.xhr?
    end

    def recent
      @title ="Recent"
      render partial: "dashboards/releases/changes", locals: {changes: recent_changes} if request.xhr?
    end

  private

    def recent_changes
      projects = Project.where(slug: %w{members unite ledger})
      releases = Release.where(project_id: projects.map(&:id)).to("production").limit(20)
      releases.flat_map(&:release_changes).take(15)
    end

    def upcoming_changes
      %w{members unite ledger}.flat_map do |slug|
        project = Project.find_by_slug slug
        master = project.repo.branch "master"
        beta = project.repo.branch "beta"
        if master && beta
          release = Release.new(project: project)
          project.commits.between(master, beta)
            .map { |commit| ReleaseChange.from_commit(release, commit) }
            .reject { |change| change.tag.nil? }
        else
          []
        end
      end
    end

  end
end
