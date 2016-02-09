class MergeMembersUniteAndLedgerRoadmaps < ActiveRecord::Migration
  def up
    members = Roadmap.find_by_name "360 Members"
    unite = Roadmap.find_by_name "360 Unite"
    ledger = Roadmap.find_by_name "360 Ledger"

    church360 = members
    church360.update_column :name, "Church360º"
    church360.project_ids = Project.where(slug: %w{members unite ledger}).pluck(:id)

    # Adjust the lanes where milestones appear
    increase_bands_by unite, 4
    increase_bands_by ledger, 5

    # Move Unite and Ledger's milestones and commits
    # to the combined roadmap
    unite.milestones.including_destroyed.update_all(roadmap_id: church360.id)
    ledger.milestones.including_destroyed.update_all(roadmap_id: church360.id)
    unite.commits.update_all(roadmap_id: church360.id)
    ledger.commits.update_all(roadmap_id: church360.id)

    unite.delete
    ledger.delete
  end

  def down
    church360 = Roadmap.find_by_name "Church360º"
    unite = Roadmap.create! name: "360 Unite"
    ledger = Roadmap.create! name: "360 Ledger"
    church360.update_column :name, "360 Members"
    church360.project_ids = Project.where(slug: %w{members}).pluck(:id)
    unite_id = Project["unite"].id
    ledger_id = Project["ledger"].id

    church360.milestones.joins(:milestone).merge(Milestone.where(project_id: unite_id)).update_all(roadmap_id: unite.id)
    church360.milestones.joins(:milestone).merge(Milestone.where(project_id: ledger_id)).update_all(roadmap_id: ledger.id)
    church360.commits.where(project_id: unite_id).update_all(roadmap_id: unite.id)
    church360.commits.where(project_id: ledger_id).update_all(roadmap_id: ledger.id)

    # Adjust the lanes where milestones appear
    increase_bands_by unite, -4
    increase_bands_by ledger, -5
  end

private

  def increase_bands_by(roadmap, offset)
    roadmap.milestones.where(band: 1).update_all(band: 1 + offset)
    roadmap.milestones.where(band: 2).update_all(band: 2 + offset)

    roadmap.commits.find_each do |commit|
      commit.milestone_versions.each do |version|
        if version.modifications.key? "band"
          before, after = version.modifications["band"]
          before += offset
          after += offset
          version.update_column :modifications, version.modifications.merge("band" => [before, after])
        end
      end
    end
  end

end
