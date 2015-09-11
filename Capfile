load "deploy"
set :application, "houston"
load File.expand_path("~/epic.cap")
set :repository, "git://github.com/concordia-publishing-house/our-houston.git"

before "bundler:install", "deploy:symlink_config"
after "deploy:setup", "deploy:create_shared_folders"

namespace :deploy do
  desc "Symlink import config files"
  task :symlink_config, :roles => :app do
    commands = [
      "mkdir -p #{release_path}/vendor",
      "ln -nfs #{shared_path}/config/keypair.pem #{release_path}/config/keypair.pem",
      "ln -nfs #{shared_path}/config/skylight.yml #{release_path}/config/skylight.yml",
      "rm -rf #{release_path}/tmp",
      "ln -nfs #{shared_path}/tmp #{release_path}",
      "ln -nfs #{shared_path}/extras #{release_path}/public/extras",
    ]
    run commands.join(" && ")
  end

  desc "Create other shared folders"
  task :create_shared_folders, :roles => :app do
    run "mkdir -p #{shared_path}/tmp"
  end
end
