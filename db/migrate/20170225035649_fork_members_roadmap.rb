class ForkMembersRoadmap < ActiveRecord::Migration[5.0]
  NEW_ROADMAP_NAME = "Church360º 2016–".freeze
  COMMIT_IDS = [94, 107, 109, 115, 121].freeze

  def up
    roadmap = Roadmap.find(2)
    new_roadmap = Roadmap.create!(
      name: NEW_ROADMAP_NAME,
      team_ids: roadmap.team_ids,
      visibility: roadmap.visibility)

    commit = RoadmapCommit.find(90)
    RoadmapCommit.create!(
      user: commit.user,
      created_at: commit.created_at,
      roadmap: new_roadmap,
      message: commit.message,
      diffs: [{
        "status" => "added",
        "milestone_id" => 396,
        "attributes" => {
          "band" => 3,
          "name" => "Winterize Church360º",
          "lanes" => 1,
          "end_date" => "2016-09-03",
          "start_date" => "2016-08-01" } }])

    RoadmapCommit.where(id: COMMIT_IDS).update_all(roadmap_id: new_roadmap.id)
  end

  def down
    Roadmap.where(name: NEW_ROADMAP_NAME).delete_all
    RoadmapCommit.where(id: COMMIT_IDS).update_all(roadmap_id: 2)
  end
end
