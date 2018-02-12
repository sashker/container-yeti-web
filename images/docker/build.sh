#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

export RAILS_ENV=production
export RACK_ENV=production
export RAKE_ENV=production
export BUNDLE_GEMFILE=/home/yeti-web/Gemfile
export GEM_PATH=/home/yeti-web/vendor/bundler

log::m-info "Adding Yeti repo to the /etc/apt"
echo "deb http://pkg.yeti-switch.org/debian/jessie stable main ext" >> /etc/apt/sources.list

log::m-info "Let's add the repo signature"
apt-key adv --keyserver keys.gnupg.net --recv-key 9CEBFFC569A832B6

log::m-info "Installing essentials ..."
apt-get update -qq
apt-get install -yqq \
	postgresql-client-9.4 \
	postgresql-contrib-9.4 \
	postgresql-9.4-prefix \
    postgresql-9.4-pgq3 \
    postgresql-9.4-yeti \
	build-essential \
	libpq-dev \
	patch \
    zlib1g-dev \
    liblzma-dev \
    ruby2.3-dev \
	ca-certificates \
	ruby2.3 \
	iputils-ping \
        curl \
	git

log::m-info "Clone $BUILD branch of $APP Release ..."
git clone -b $BUILD https://github.com/yeti-switch/yeti-web.git /home/yeti-web

log::m-info "We have to create user $USER"
build::user::create $USER

log::m-info "Go straight to home directory"
cd $HOME

log::m-info "Set permissions for the project directory"
chown -R $USER:$USER /home/yeti-web

log::m-info "We are going to install some bundles for Yeti web"
export RAILS_ENV=production
export RACK_ENV=production
export RAKE_ENV=production
export BUNDLE_GEMFILE=/home/yeti-web/Gemfile
export GEM_PATH=/home/yeti-web/vendor/bundler
gem install bundler

log::m-info "Writing $APP database.yml ..."
cat > /home/yeti-web/config/database.yml <<EOF
production:
  adapter: postgresql
  encoding: unicode
  database: $ROUTING_DB_NAME
  pool: 5
  username: $ROUTING_POSTGRES_USER
  password: $ROUTING_POSTGRES_PASSWORD
  host: $ROUTING_POSTGRES_HOST
  schema_search_path: 'gui,public,switch,billing,class4,runtime_stats,sys,logs,data_import'
  port: $ROUTING_POSTGRES_PORT
  min_messages: notice

secondbase:
  production:
    adapter: postgresql
    encoding: unicode
    database: $CDR_DB_NAME
    pool: 5
    username: $CDR_POSTGRES_USER
    password: $CDR_POSTGRES_PASSWORD
    host: $CDR_POSTGRES_HOST
    schema_search_path: 'cdr,reports,billing'
    port: $CDR_POSTGRES_PORT
    min_messages: notice
EOF

#log::m-info "Update gems for production mode..."
#bundle install

log::m-info "Install gems for production mode..."
bundle install --jobs=4 --binstubs --without development test

log::m-info "Generating bin/delayed_job..."
bundle exec rails generate delayed_job

log::m-info "Trying to precompile assets..."
bundle exec rake assets:precompile

log::m-info "We are going to install some bundles for Yeti CDR billing"
cd /home/yeti-web/pgq-processors
export BUNDLE_GEMFILE=/home/yeti-web/pgq-processors/Gemfile
export GEM_PATH=/home/yeti-web/pgq-processors/vendor/bundler
gem install bundler
#gem install rake -v '12.0.0'
bundle install --jobs=4 --frozen --deployment --binstubs --path=$GEM_PATH

log::m-info "Removing unnecessary dependencies ..."
apt-get purge -y --auto-remove jq git build-essential libpq-dev patch zlib1g-dev liblzma-dev

log::m-info "Cleaning up ..."
apt-clean --aggressive
rm -rf /home/yeti-web/swagger

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
