require "engineyard"
require "engineyard/cli"

module Deployers
  class Engineyard
    attr_reader :project, :environment_name

    def initialize(project, environment_name)
      @project = project
      @environment_name = environment_name

      @config = Config.new(project.read_file("config/ey.yml"))
      @ui = EY::CLI::UI.new
      @api = EY::CLI::API.new(config.endpoint, ui, ENV["HOUSTON_ENGINEYARD_API_TOKEN"])
      @repo = nil
    end


    def last_deploy_commit
      app_env.last_deployment.commit
    end


    # https://github.com/engineyard/engineyard/blob/v3.0.1/lib/engineyard/cli.rb#L123
    def deploy(deploy, options={})
      config_override = { maintenance_on_migrate: options[:maintenance_page] }
      config_override[:precompile_assets] = options[:precompile_assets] if options.key? :precompile_assets
      config_override[:precompile_unchanged_assets] = options[:precompile_unchanged_assets] if options.key? :precompile_unchanged_assets
      options = {
        ref: deploy.branch,
        environment: environment_name,
        config: config_override
      }.with_indifferent_access

      env_config = config.environment_config(app_env.environment_name)
      deploy_config = EY::DeployConfig.new(options, env_config, repo, ui)

      deployment = app_env.new_deployment(
        ref:                deploy_config.ref,
        migrate:            deploy_config.migrate,
        migrate_command:    deploy_config.migrate_command,
        extra_config:       deploy_config.extra_config,
        serverside_version: EY::ENGINEYARD_SERVERSIDE_VERSION)

      runner = EY::ServersideRunner.new(
        bridge:             app_env.environment.bridge!(options[:ignore_bad_master]).hostname,
        app:                app_env.app,
        environment:        app_env.environment,
        verbose:            deploy_config.verbose,
        serverside_version: EY::ENGINEYARD_SERVERSIDE_VERSION)

      # Triplicate:
      #  1. standard output gets a copy
      #  2. the Deploy model gets a copy
      #  3. EngineYard gets a copy
      out = EY::CLI::UI::Tee.new(ui.out, deploy.output_stream, deployment.output)
      err = EY::CLI::UI::Tee.new(ui.err, deploy.output_stream, deployment.output)

      deployment.start

      begin
        ui.show_deployment(deployment)

        runner.deploy do |args|
          args.config = deployment.config if deployment.config
          if deployment.migrate
            args.migrate = deployment.migrate_command
          else
            args.migrate = false
          end
          args.ref = deployment.resolved_ref
        end

        deployment.successful = runner.call(out, err)

        Houston.try({max_tries: 5, ignore: true}, exceptions_wrapping(PG::ConnectionBad)) do
          deploy.update_attributes!(successful: deployment.successful, completed_at: Time.now)
        end

      rescue StandardError => e
        Houston.report_exception(e)
        deployment.err << "Error encountered during deploy.\n#{e.class} #{e}\n"
        ui.print_exception(e)

      ensure
        deployment.finished
      end

      deployment.successful?
    end

  private
    attr_reader :config, :ui, :api, :repo

    def app_env
      @app_env ||= begin
        resolver = api.resolve_app_environments(
          account_name: "EP",
          app_name: project.slug,
          environment_name: environment_name)
        resolver.matches.first
      end
    end

    class Config < EY::Config
      def initialize(config)
        @path = Struct.new(:exist?).new(true)
        @config = YAML.load(config) || {} # load_file returns `false' when the file is empty
        raise "ey.yml load error: Expected a Hash but a #{config.class.name} was returned." unless Hash === @config
        @config["environments"] ||= {}
      end
    end

  end
end
