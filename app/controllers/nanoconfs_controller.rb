class NanoconfsController < ApplicationController
  before_action :set_presentation, only: [:show, :edit, :update]
  before_action :set_presentations, only: [:index, :new, :edit]
  attr_reader :presentations, :presentation

  layout "instance_application"
  helper Houston::Engine.routes.url_helpers
  include Houston::Engine.routes.url_helpers

  def index
    authorize! :read, Nanoconf
  end

  def show
    authorize! :read, @presentation
  end

  def new
    new_presentation_date = Date.today
    new_presentation_date = params[:date].to_date if params[:date]
    @presentation = Nanoconf.new(date: new_presentation_date)
    authorize! :create, @presentation
    @dropdown_dates = get_dropdown_dates
  end

  def create
    presentation = Nanoconf.new(presentation_params)
    authorize! :create, presentation
    if presentation.save
      flash[:notice] = "Presentation Created!"
      Houston.observer.fire "nanoconf:create", nanoconf: presentation
      redirect_to presentation
    else
      flash[:error] = "There was an error saving your presentation"
      redirect_to new_nanoconf_path
    end
  end

  def edit
    authorize! :update, @presentation
    @dropdown_dates = get_dropdown_dates
    @presentation.tags = @presentation.tags.join(", ") if @presentation.tags
  end

  def update
    authorize! :update, @presentation
    @presentation.presenter = current_user

    if presentation.update_attributes(presentation_params)
      flash[:notice] = "Presentation Updated!"
      Houston.observer.fire "nanoconf:update", nanoconf: presentation
      redirect_to presentation
    else
      flash[:error] = "There was a problem"
    end
  end

  def past
    @presentations = Nanoconf.where("date < ?", Date.today)
  end

private

  def set_presentation
    @presentation = Nanoconf.find(params[:id])
    @presentation_list_path = @presentation.past? ?  past_nanoconfs_path : nanoconfs_path
  end

  def get_dropdown_dates
    @presentations.select do |friday, nanoconf|
      nanoconf.nil? || (params[:action] == "edit" && nanoconf.id == params[:id].to_i)
    end.keys.map { |date| date.strftime("%B %d, %Y") }
  end

  def next_six_months
    start_date = Date.today
    end_date = Date.today + 6.months
    my_days = [5] # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
    (start_date..end_date).to_a.select {|k| my_days.include?(k.wday)}
  end


  def presentation_params
    permitted_params = params.require(:nanoconf).permit(:title, :description, :date, :tags, :presenter)
    permitted_params[:date] = permitted_params[:date].to_date if permitted_params[:date]
    permitted_params[:tags] = permitted_params[:tags].split(',').map(&:strip)

    presenter_email = permitted_params.delete(:presenter)
    permitted_params[:presenter] = current_user

    permitted_params
  end

  def set_presentations
    @presentations = next_six_months.each_with_object({}) do |friday, presentations|
      nanoconf = Nanoconf.find_by(date: friday)
      presentations[friday] = nanoconf
    end
  end

end
