class PianistsController < ApplicationController
  before_action :find_upcoming_pianists, only: %i{index}
  before_action :find_eligible_pianists, only: %i{new edit}
  before_action :find_pianist, only: %i{show edit update destroy}

  def index
    authorize! :read, Pianist
  end

  def show
    authorize! :read, @pianist
  end

  def new
    authorize! :create, @pianist
    year = params.fetch(:year, Date.today.year)
    month = params.fetch(:month, Date.today.month)
    @pianist = Pianist.new(year: year, month: month)
  end

  def edit
    authorize! :update, @pianist
  end

  def create
    pianist = Pianist.new(create_params)
    authorize! :create, pianist
    if pianist.save
      flash[:notice] = "Pianist assigned"
      redirect_to pianist_path(pianist)
    else
      flash[:error] = "There was an error assigning the pianist"
      redirect_to new_pianist_path
    end
  end

  def update
    authorize! :update, @pianist

    if @pianist.update_attributes(update_params)
      flash[:notice] = "Pianist assignment updated"
      redirect_to pianist_path(@pianist)
    else
      flash[:error] = "There was a problem updating pianist assignment"
    end
  end

  def destroy
    authorize! :destroy, @pianist
    if @pianist.destroy
      redirect_to pianists_path
    else
      flash[:error] = "There was a problem deleting your pianist assignment"
    end
  end

private

  def find_pianist
    @pianist = Pianist.find(params[:id])
  end

  def create_params
    params.require(:pianist).permit(:year, :month, :user_id)
  end
  alias update_params create_params

  def find_eligible_pianists
    @eligible_pianists = Team.find_by(name: "Chapel")
      .users
      .where("'Tester' = ANY(teams_users.roles)")
      .pluck("users.first_name", "users.last_name", "users.id")
      .map { |first_name, last_name, id| [ "#{first_name} #{last_name}", id ] }
  end

  def upcoming_months
    @upcoming_months ||= begin
      now = Date.today
      year = now.year
      (now.month...(now.month + 7)).map { |month|
        next_year = month > 12
        month = month % 12
        month = 12 if month.zero?
        [ next_year ? year + 1 : year, month ]
      }
    end
  end

  def find_upcoming_pianists
    pianists = pianists.upcoming.limit(7).to_a
    @upcoming_pianists = upcoming_months.map { |(year, month)|
      [ Date(year, month, 1).strftime("%B %Y"), pianists.find { |p| p.year == year && p.month == month } ]
    }
  end

end
