# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config do


  role "Maintainer" do |team|
    can :manage, Houston::Releases::Release, project_id: team.project_ids
    can :update, Project, id: team.project_ids
    can :close, Ticket, project_id: team.project_ids
    can :estimate, Project, id: team.project_ids # <-- !todo: remove
  end


  role "Developer" do |team|
    can :read, Commit, project_id: team.project_ids
    can :manage, Task, project_id: team.project_ids
    can :manage, Ticket, project_id: team.project_ids
    can :manage, Github::PullRequest, project_id: team.project_ids
    can :manage, Houston::Alerts::Alert, project_id: team.project_ids
  end


  # Testers can create tickets and be assigned Alerts
  role "Tester" do |team|
    can :create, Ticket, project_id: team.project_ids
    can :manage, Houston::Alerts::Alert, project_id: team.project_ids
  end


  # Product Owners can prioritize tickets
  role "Product Owner" do |team|
    can :prioritize, Project, id: team.project_ids
  end


  role "Team Owner" do |team|
    can [:update, :destroy], Houston::Feedback::Conversation, project_id: team.project_ids
    can :manage, Roadmap, id: team.roadmap_ids
    can :manage, Roadmap do |roadmap|
      roadmap.team_ids.member?(team.id)
    end
    can :manage, Milestone, project_id: team.project_ids
    can :manage, Goal, project_id: team.project_ids
  end


  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Houston::Releases::Release do |release|
        release.environment_name == "production"
      end

    else

      if user.admin?

        # Admins can see and run Actions
        can :read, Action
        can :run, Action

      end

      # Employees can see the Nanoconf schedule
      can :read, Nanoconf

      # Employees can see Releases to staging
      can :read, Houston::Releases::Release

      # Employees can see Projects
      can :read, Project

      # Employees can see Tickets
      can :read, Ticket

      # Employees can see Roadmaps that are visible to Everyone
      can :read, Roadmap, visibility: "Everyone"
      can :read, Milestone
      can :read, Goal # <-- this could optionally be just for projects that belong
                      #     to teams you're on, but I don't think it needs to be.

      # Employees can authorize Houston to use third-party services
      # and can see their own authorizations
      can :create, Authorization
      can :manage, Authorization, user_id: user.id

      # Team Members can see Roadmaps that are visible to them
      can :read, Roadmap do |roadmap|
        roadmap.visibility == "Team Members" && (roadmap.team_ids & user.team_ids).any?
      end

      # Employees can see Users and update themselves
      can :read, User
      can :update, user

      # Employees can see project quotas
      can :read, Houston::Scheduler::ProjectQuota

      # Employees can read and tag and create and comment on feedback
      can :read, Houston::Feedback::Conversation
      can :tag, Houston::Feedback::Conversation
      can :create, Houston::Feedback::Conversation
      can :comment_on, Houston::Feedback::Conversation

      # Employees can update their own feedback
      can [:update, :destroy], Houston::Feedback::Conversation, user_id: user.id

      # Folks can update their own presentations
      can [:update, :destroy], Nanoconf, presenter_id: user.id

      # If you're signed in, you can create a Nanoconfs
      can :create, Nanoconf

      # Matt can manage Nanoconfs
      can :manage, Nanoconf if user.email == MATT

    end
  end
end
