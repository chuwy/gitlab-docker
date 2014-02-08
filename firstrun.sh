#!/bin/bash

# Regenerate the SSH host key
/bin/rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

DBHOST=$(cat /srv/gitlab/config/database.yml | grep -m 1 host | sed -e 's/  host: "//g')
DBPASS=$(cat /srv/gitlab/config/database.yml | grep -m 1 password | sed -e 's/  password: "//g' | sed -e 's/"//g')

# === Delete this section if restoring data from previous build ===

# Precompile assets
cd /home/git/gitlab
su git -c "bundle exec rake assets:precompile RAILS_ENV=production"

# Initialize Database
echo "CREATE USER git" | psql --username=postgres --host=$DBHOST -d template1
echo "CREATE DATABASE gitlabhq_production OWNER git;" | psql --username=postgres --host=$DBHOST -d template1

cd /home/git/gitlab
su git -c "bundle exec rake gitlab:setup force=yes RAILS_ENV=production"
sleep 5
su git -c "bundle exec rake db:seed_fu RAILS_ENV=production"

# ================================================================

# Delete firstrun script
rm /srv/gitlab/firstrun.sh
