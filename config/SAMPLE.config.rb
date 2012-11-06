# Customize this file, and then rename it to config.rb

set :application, "WP Stack Site"
set :repository,  "file:////home/git/app_user.git"
set :local_repository,  "git@[server ip]:app_user.git"
set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

# Using Git Submodules?
set :git_enable_submodules, 1

# This should be the same as :deploy_to in production.rb
set :production_deploy_to, '/home/app_user/app'

# The domain name used for your staging environment
set :staging_domain, 'staging.example.com'

# Database
# Set the values for host, user, pass, and name for both production and staging.
set :wpdb do
  {
    :production => {
      :host     => 'localhost',
      :user     => 'PRODUCTION DB USER',
      :password => 'PRODUCTION DB PASS',
      :name     => 'PRODUCTION DB NAME',
    },
    :staging => {
      :host     => 'localhost',
      :user     => 'STAGING DB USER',
      :password => 'STAGING DB PASS',
      :name     => 'STAGING DB NAME',
    }
  }
end

# You're not done! You must also configure production.rb and staging.rb
