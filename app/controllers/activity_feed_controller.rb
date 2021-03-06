# TODO: figure out how to get helpers to work here...
require_dependency "../helpers/timeline_helper"

class ActivityFeedController < ApplicationController
  before_action :authenticate_user!
  layout "minimal"

  helper ::TimelineHelper
  helper Houston::Releases::ReleaseHelper
  helper TicketHelper

  def index
    load_activity
    render partial: "activity_feed/events" if request.xhr?
  end

private

  def load_activity
    if params[:since]
      time = Time.parse(params[:since])
      @last_date = time.to_date
    else
      time = Time.now
      @last_date = nil
    end

    @events = ActivityFeed.new(followed_projects, time, count: 150).events
  end

end
