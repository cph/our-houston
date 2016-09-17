module Gemnasium
  class Alert

    def self.all
      response = $gemnasium.get "projects"
      projects = MultiJson.load(response.body).values.flatten

      projects.flat_map do |project|
        response = $gemnasium.get "projects/#{project["slug"]}/alerts"
        Array(MultiJson.load(response.body)).map { |alert| alert.merge(
          "project_id" => project["slug"],
          "project_slug" => project["name"]) }
      end.compact
    end

    def self.open
      all.select { |alert| alert["status"] != "closed" }
    end

  end
end
