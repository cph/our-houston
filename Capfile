load "deploy"
set :application, "houston"
load File.expand_path("~/epic.cap")
set :repository, "https://github.com/cph/our-houston.git"

before "bundler:install", "deploy:symlink_config"
after "deploy:setup", "deploy:create_shared_folders"

namespace :deploy do
  desc "Symlink import config files"
  task :symlink_config, :roles => :app do
    commands = [
      "mkdir -p #{release_path}/vendor",
      "ln -nfs #{shared_path}/config/keypair.pem #{release_path}/config/keypair.pem",
      "ln -nfs #{shared_path}/config/skylight.yml #{release_path}/config/skylight.yml",
      "ln -nfs #{shared_path}/config/cable.yml #{release_path}/config/cable.yml",
      "rm -rf #{release_path}/tmp",
      "ln -nfs #{shared_path}/tmp #{release_path}" ]
    run commands.join(" && ")
  end

  desc "Create other shared folders"
  task :create_shared_folders, :roles => :app do
    run "mkdir -p #{shared_path}/tmp"
  end
end
