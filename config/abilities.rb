# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config.abilities do |user|
  if user.nil?

    # Customers are allowed to see Release Notes of products, for production
    can :read, Release do |release|
      release.environment_name == "production"
    end

    # Customers are allowed to see Features, Improvements, and Bugfixes
    can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

  else

    # Everyone can see Releases to staging
    can :read, Release

    # Everyone is allowed to see Features, Improvements, and Bugfixes
    can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

    # Everyone can see Projects
    can :read, Project

    # Everyone can see Tickets
    can :read, Ticket

    # Everyone can see Roadmaps
    can :read, Roadmap
    can :read, Milestone

    # Everyone can see Users and update themselves
    can :read, User
    can :update, user

    # Everyone can make themselves a "Follower"
    can :create, Role, name: "Follower"

    # Everyone can remove themselves from a role
    can :destroy, Role, user_id: user.id

    # Everyone can edit their own testing notes
    can [:update, :destroy], TestingNote, user_id: user.id

    # Everyone can see project quotas
    can :read, Houston::Scheduler::ProjectQuota

    # Everyone can read and tag and create feedback
    can :read, Houston::Feedback::Comment
    can :tag, Houston::Feedback::Comment
    can :create, Houston::Feedback::Comment

    # Everyone can update their own feedback
    can [:update, :destroy], Houston::Feedback::Comment, user_id: user.id

    # The Nanoconf officer can update all the presentations
    can :update, Houston::Nanoconfs::Presentation if user.email == "chase.clettenberg@cph.org"

    # Folks can update their own presentations
    can :update, Houston::Nanoconfs::Presentation, presenter_id: user.id

    # Developers can
    #  - create tickets
    #  - see other kinds of Release Changes (like Refactors)
    #  - update Sprints
    #  - change Milestones' tickets
    #  - break tickets into tasks
    if user.developer?
      can :read, [Commit, ReleaseChange]
      can :manage, Sprint
      can :update_tickets, Milestone
      can :manage, Task
      can :manage, Github::PullRequest
      can :read, :star_report
    end

    # Testers and Developers can
    #  - see and comment on all testing notes
    #  - create tickets
    #  - see and manage alerts
    if user.tester? or user.developer?
      can :create, Ticket
      can [:create, :read], TestingNote
      can :manage, Houston::Alerts::Alert
    end

    # The following abilities are project-specific and depend on one's role
    roles = user.roles.participants
    if roles.any?

      # Everyone can see and comment on Testing Reports for projects they are involved in
      can [:create, :read], TestingNote, project_id: roles.pluck(:project_id)

      # Maintainers can manage Releases, close and estimate Tickets, and update Projects
      roles.maintainers.pluck(:project_id).tap do |project_ids|
        can :manage, Release, project_id: project_ids
        can :update, Project, id: project_ids
        can :close, Ticket, project_id: project_ids
        can :estimate, Project, id: project_ids # <-- !todo: remove
      end

      # Product Owners can prioritize tickets
      can :prioritize, Project, id: roles.owners.pluck(:project_id)
    end
  end
end
