namespace :shared do
  task :make_shared_dir do
    run "if [ ! -d #{shared_path}/files ]; then mkdir #{shared_path}/files; fi"
  end
  task :make_symlinks do
    run "if [ ! -h #{release_path}/shared ]; then ln -s #{shared_path}/files/ #{release_path}/shared; fi"
    run "for p in `find -L #{release_path} -type l`; do t=`readlink $p | grep -o 'shared/.*$'`; #{try_sudo} mkdir -p #{release_path}/$t; done"
    # no need to chown path
    #run "#{try_sudo} chown #{user}:www-data #{release_path}/$t; done"
  end
end

namespace :nginx do
  desc "Restarts nginx"
  task :restart do
    run "sudo /etc/init.d/nginx restart"
  end
end

namespace :phpfpm do
  desc" Restarts PHP-FPM"
  task :restart do
    run "sudo /etc/init.d/php-fpm restart"
  end
end

namespace :git do
  desc "Updates git submodule tags"
  task :submodule_tags do
    run "if [ -d #{shared_path}/cached-copy/ ]; then cd #{shared_path}/cached-copy/ && git submodule foreach --recursive git fetch origin --tags; fi"
  end
end

namespace :memcached do
  desc "Restarts Memcached"
  task :restart do
    run "echo 'flush_all' | nc localhost 11211", :roles => [:memcached]
  end
  desc "Updates the pool of memcached servers"
  task :update do
    unless find_servers( :roles => :memcached ).empty? then
      mc_servers = '<?php return array( "' + find_servers( :roles => :memcached ).join( ':11211", "' ) + ':11211" ); ?>'
      run "echo '#{mc_servers}' > #{current_path}/memcached.php", :roles => :memcached
    end
  end
end

namespace :db do
  desc "Syncs the staging database (and uploads) from production"
  task :sync, :roles => :web  do
    if stage != :staging then
      puts "[ERROR] You must run db:sync from staging with cap staging db:sync"
    else
      puts "Hang on... this might take a while."
      random = rand( 10 ** 5 ).to_s.rjust( 5, '0' )
      p = wpdb[ :production ]
      s = wpdb[ :staging ]
      puts "running db:sync"
      puts stage
      # system and run are behaving differently in regards to the credentials
      md = "mysqldump -u #{p[:user]} --opt --no-create-db --result-file=/tmp/wpstack-#{random}.sql -h #{p[:host]} --password=#{p[:password]} --database #{p[:name]}"
      #puts "MYSQLDUMP call: #{md}"
      #system "mysqldump -u #{p[:user]} --result-file=/tmp/wpstack-#{random}.sql -h #{p[:host]} --password=#{p[:password]} --database #{p[:name]}"
      #system md
      run md

      my = "mysql -u #{s[:user]} -h #{s[:host]} --password=#{s[:password]} --one-database --database #{s[:name]} < /tmp/wpstack-#{random}.sql && rm /tmp/wpstack-#{random}.sql"
      #puts "MYSQL Insert: #{my}"
      #system "mysql -u #{s[:user]} -h #{s[:host]} --password=#{s[:password]} #{s[:name]} < /tmp/wpstack-#{random}.sql && rm /tmp/wpstack-#{random}.sql"
      run my

      #TODO handle errors better
      puts "Database synced to staging"
      # memcached.restart
      #puts "Memcached flushed"

      # Now to copy files
      # File copy errors out as well
      find_servers( :roles => :web ).each do |server|
        puts "STAGING SYNC PATH: #{server}:#{shared_path}/files/"
        puts "PRODUCTION SYNC PATH: #{production_deploy_to}/shared/files/"
        puts "running rsync"
        system "rsync -avz --delete #{production_deploy_to}/shared/files/ #{server}:#{shared_path}/files/"
      end
    end
  end
  desc "Sets the database credentials (and other settings) in wp-config.php"
  task :make_config do
    staging_domain ||= ''
    {:'%%WP_STAGING_DOMAIN%%' => staging_domain, :'%%WP_STAGE%%' => stage, :'%%DB_NAME%%' => wpdb[stage][:name], :'%%DB_USER%%' => wpdb[stage][:user], :'%%DB_PASSWORD%%' => wpdb[stage][:password], :'%%DB_HOST%%' => wpdb[stage][:host]}.each do |k,v|
      #FIXME complicated passwords will break sed as they are not escaped. 
      run "sed -i 's/#{k}/#{v}/' #{release_path}/wp-config.php", :roles => :web
    end
  end
end
