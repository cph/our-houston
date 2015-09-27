require_relative "../../lib/side_projects"

module Houston
  def self.side_projects
    @side_projects ||= SideProjects.new
  end
end
