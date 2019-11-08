require "platform-api"
require "netrc"

module Deployers
  class Heroku
    attr_reader :project, :environment_name

    class Logger
      attr_reader :streams

      def initialize(*streams)
        @streams = streams
      end

      def output(str)
        streams.each { |stream| stream.puts str }
      end
      alias info output
      alias debug output
    end

    def initialize(project, environment_name)
      @project = project
      @environment_name = environment_name
    end

    def last_deploy_commit
      releases = heroku.release.list(app_name).to_a
      id = releases.last.fetch("slug").fetch("id")
      slug = heroku.slug.info(app_name, id)
      slug.fetch("commit")
    end

    def deploy(deploy, options={})
      begin
        project.repo.refresh!

        rugged_repo = project.repo.send(:connection)
        branch_ref = rugged_repo.refs.find { |ref| ref.target_id == deploy.sha }
        heroku_remote = rugged_repo.remotes.create_anonymous(heroku_git_url)

        # The + in the refspec means --force
        result = heroku_remote.push(
          [ "+#{branch_ref.canonical_name}:refs/heads/master" ],
          progress: ->(txt) { deploy.output_stream << txt },
          credentials: heroku_credentials

        successful = result.empty?
        record_outcome_of! deploy, successful: successful
      rescue Exception
        record_outcome_of! deploy, successful: false
        raise
      end

      deploy.successful?
    end

  private

    def app_name
      app_name = "#{project.slug}-#{environment_name}".gsub("_", "-")
      HEROKU_ALIASES.fetch(app_name, app_name)
    end

    def heroku_git_url
      "https://git.heroku.com:#{app_name}.git"
    end

    def heroku
      @heroku ||= PlatformAPI.connect_oauth ENV["HOUSTON_PLATFORM_API_OAUTH_TOKEN"]
    end

    def heroku_credentials
      netrc = Netrc.read(File.expand_path("~/.netrc"))
      user, pass = netrc["git.heroku.com"]
      Rugged::Credentials::UserPassword.new(username: user, password: pass)
    end

    def record_outcome_of!(deploy, successful: true)
      Houston.try({ max_tries: 5, ignore: true }, exceptions_wrapping(PG::ConnectionBad)) do
        deploy.update! successful: successful, completed_at: Time.now
      end
    end

    HEROKU_ALIASES = {
      "members-production" => "members-production-8081",
      "members-staging2" => "members-staging",
      "mss-staging" => "music-subscription-staging"
    }.freeze

  end
end
