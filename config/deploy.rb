require 'bundler/capistrano'
require 'rvm/capistrano'
 
# This capistrano deployment recipe is made to work with the optional
# StackScript provided to all Rails Rumble teams in their Linode dashboard.
#
# After setting up your Linode with the provided StackScript, configuring
# your Rails app to use your GitHub repository, and copying your deploy
# key from your server's ~/.ssh/github-deploy-key.pub to your GitHub
# repository's Admin / Deploy Keys section, you can configure your Rails
# app to use this deployment recipe by doing the following:
#
# 1. Add `gem 'capistrano', '~> 2.15'` to your Gemfile.
# 2. Run `bundle install --binstubs --path=vendor/bundles`.
# 3. Run `bin/capify .` in your app's root directory.
# 4. Replace your new config/deploy.rb with this file's contents.
# 5. Configure the two parameters in the Configuration section below.
# 6. Run `git commit -a -m "Configured capistrano deployments."`.
# 7. Run `git push origin master`.
# 8. Run `bin/cap deploy:setup`.
# 9. Run `bin/cap deploy:migrations` or `bin/cap deploy`.
#
# Note: You may also need to add your local system's public key to
# your GitHub repository's Admin / Deploy Keys area.
#
# Note: When deploying, you'll be asked to enter your server's root
# password. To configure password-less deployments, see below.
 
#############################################
##                                         ##
##              Configuration              ##
##                                         ##
#############################################
 
SERVER_NAME = 're.invent.to' #107.170.19.251'
 
#############################################
#############################################
 
# General Options
 
set :bundle_flags,               "--deployment"
 
set :application,                "reinventto"
set :deploy_to,                  "/var/www/apps/reinventto"
set :normalize_asset_timestamps, false
set :rails_env,                  "production"
 
set :user,                       "root"
set :runner,                     "www-data"
set :admin_runner,               "www-data"


set :rvm_ruby_string, 'ruby-2.0.0-p0'
set :rvm_type, :system
 
# Password-less Deploys (Optional)
#
# 1. Locate your local public SSH key file. (Usually ~/.ssh/id_rsa.pub)
# 2. Execute the following locally: (You'll need your Linode server's root password.)
#
#    cat ~/.ssh/id_rsa.pub | ssh root@SERVER_NAME "cat >> ~/.ssh/authorized_keys"
#
# 3. Uncomment the below ssh_options[:keys] line in this file.
#
ssh_options[:keys] = ["~/.ssh/id_rsa"]
 
# SCM Options
set :scm,        :git
set :repository, "git@github.com:inventto/reinventto.git"
set :branch,     "master"

# Roles
role :app, SERVER_NAME
role :db,  SERVER_NAME, :primary => true
# Add Configuration Files & Compile Assets
namespace :deploy do
  desc "Stopping thin"
  task :stop do
    run "source ~/.bashrc; cd #{current_path} && thin stop"
  end
  desc "Starting thin"
  task :start  do
    run "source ~/.bashrc; cd #{current_path} && bundle exec thin start -p 3000 -e production -d"
  end
  task :restart do
    stop
    start
  end
end

after 'deploy:update_code' do
  # Setup Configuration
  run "cp #{shared_path}/config/database.yml #{release_path}/config/database.yml"
 
  # Compile Assets

  run "cd #{release_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  sudo "chown -R www-data:www-data #{current_path}"
  sudo "chown -R www-data:www-data #{latest_release}"
  sudo "chown -R www-data:www-data #{shared_path}/bundle"
  sudo "chown -R www-data:www-data #{shared_path}/log"
  sudo "chown -R www-data:www-data #{shared_path}/db"
  run "ln -nfs #{shared_path}/uploads #{release_path}/public/system/uploads"
  run "ln -nfs #{shared_path}/db/production.sqlite3 #{release_path}/db/production.sqlite3"
  run "ln -nfs #{shared_path}/db/production.sqlite3 #{release_path}/db/development.sqlite3"

end
 
role :resque_worker, SERVER_NAME
role :resque_scheduler, SERVER_NAME

set :workers, :create_video => 2
after "deploy:restart", "resque:restart"
