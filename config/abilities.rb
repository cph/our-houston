# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config do


  role "Maintainer" do |team|
    can :manage, Release, project_id: team.project_ids
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
    can :manage, Milestone, project_id: team.project_ids
  end


  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Release do |release|
        release.environment_name == "production"
      end

    else

      if user.admin?

        # Admins can see Actions
        can :read, Action

      end

      # Employees can see the Nanoconf schedule
      can :read, Nanoconfs::Presentation

      # Employees can see Releases to staging
      can :read, Release

      # Employees can see Projects
      can :read, Project

      # Employees can see Tickets
      can :read, Ticket

      # Employees can see Roadmaps
      can :read, Roadmap
      can :read, Milestone

      # Employees can see Users and update themselves
      can :read, User
      can :update, user

      # Employees can edit their own testing notes
      can [:update, :destroy], TestingNote, user_id: user.id

      # Employees can see project quotas
      can :read, Houston::Scheduler::ProjectQuota

      # Employees can read and tag and create and comment on feedback
      can :read, Houston::Feedback::Conversation
      can :tag, Houston::Feedback::Conversation
      can :create, Houston::Feedback::Conversation
      can :comment_on, Houston::Feedback::Conversation

      # Employees can update their own feedback
      can [:update, :destroy], Houston::Feedback::Conversation, user_id: user.id

      # The Nanoconf officer can update all the presentations
      can :update, Nanoconfs::Presentation if user.email == "chase.clettenberg@cph.org"

      # Folks can update their own presentations
      can :update, Nanoconfs::Presentation, presenter_id: user.id

      # If you're signed in, you can create a Nanoconfs
      can :create, Nanoconfs::Presentation

      # Employees can see and comment on Testing Reports for projects they are involved in
      can [:create, :read], TestingNote, project_id: user.teams.project_ids

    end
  end
end
