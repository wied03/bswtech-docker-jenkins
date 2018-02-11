#!/usr/bin/env bash
echo "Launching Rack in background"
INDEX_DIRECTORY=gem_index rackup -I ../lib ../lib/bsw_tech/jenkins_gem/config.ru &
RACKUP_PID=$!
echo "Running bundle install"
bundle install
echo "Killing Rack"
kill $RACKUP_PID
PLUGIN_DEST_DIR=plugins_final bundle exec ruby ../lib/bsw_tech/jenkins_gem/bundler_copy.rb
