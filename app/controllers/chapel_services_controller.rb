class ChapelServicesController < ApplicationController
  before_action :find_service, only: %i{show edit update destroy send_summary}
  before_action :find_services, only: %i{index new edit}

  attr_reader :service, :services

  layout "instance_application"
  helper Houston::Engine.routes.url_helpers
  include Houston::Engine.routes.url_helpers

  def index
    authorize! :read, Presentation::ChapelService
  end

  def show
    authorize! :read, service
  end

  def new
    new_presentation_date = Date.today
    new_presentation_date = params[:date].to_date if params[:date]
    @service = Presentation::ChapelService.new(date: new_presentation_date)
    authorize! :create, service
    @dropdown_dates = get_dropdown_dates
    @form_path = chapel_services_path
    chapel_speakers
  end

  def create
    service = Presentation::ChapelService.new(create_params)
    authorize! :create, service
    if service.save
      flash[:notice] = "Chapel service created!"
      Houston.observer.fire "chapel_service:create", service: service
      redirect_to chapel_service_path(service)
    else
      flash[:error] = "There was an error saving your chapel service"
      redirect_to new_chapel_service_path
    end
  end

  def edit
    authorize! :update, service
    @dropdown_dates = get_dropdown_dates
    @form_path = chapel_service_path(service)
    chapel_speakers
  end

  def update
    authorize! :update, service

    if service.update_attributes(update_params)
      flash[:notice] = "Chapel service updated!"
      Houston.observer.fire "chapel_service:update", service: service
      redirect_to chapel_service_path(service)
    else
      flash[:error] = "There was a problem"
    end
  end

  def destroy
    authorize! :destroy, service
    if service.destroy
      redirect_to chapel_services_path
    else
      flash[:error] = "There was a problem deleting your chapel service"
    end
  end

  def past
    @services = Presentation::ChapelService.preload(:presenter).where("date < ?", Date.today).order(date: :desc)
  end

  def send_summary
    @service.send_summary!
    flash[:notice] = "Summary sent!"
    redirect_to chapel_service_path(@service)
  end

private

  def find_service
    @service = Presentation::ChapelService.preload(:presenter).find(params[:id])
    @service_list_path = @service.past? ? past_chapel_services_path : chapel_services_path
  end

  def get_dropdown_dates
    @services.select do |wednesday, service|
      service.nil? || (params[:action] == "edit" && service.id == params[:id].to_i)
    end.keys.map { |date| date.strftime("%B %d, %Y") }
  end

  def upcoming_wednesdays
    @upcoming_wednesdays ||= (Date.today...6.months.from_now).select { |date| date.wday == 3 } # wednesdays
  end

  def create_params
    update_params.tap do |attributes|
      attributes[:presenter] ||= current_user
    end
  end

  def update_params
    attributes = params.require(:chapel_service).permit(:presenter_id, :date, :hymn, :liturgy, :joined_readings)
    attributes[:readings] = attributes.delete(:joined_readings).split("\n").map(&:strip)
    attributes[:presenter] = User.find attributes.delete(:presenter_id) if attributes.key?(:presenter_id)

    attributes
  end

  def find_services
    services = Presentation::ChapelService.preload(:presenter).where(date: upcoming_wednesdays)
    @services = upcoming_wednesdays.each_with_object({}) do |wednesday, by_date|
      by_date[wednesday] = services.find { |service| service.date == wednesday }
    end
  end

  def chapel_speakers
    @chapel_speakers ||= Team.find_by(name: "Chapel")
      .users
      .where("'Developer' = ANY(teams_users.roles)")
      .pluck("users.first_name", "users.last_name", "users.id")
      .map { |first_name, last_name, id| [ "#{first_name} #{last_name}", id ] }
  end

end
