#!/usr/bin/env bash
# TODO: Turn this into a Ruby executable that goes into the library

echo "Launching Rack in background"
INDEX_DIRECTORY=gem_index rackup -I ../lib ../lib/bsw_tech/jenkins_gem/config.ru &
RACKUP_PID=$!
echo "Running bundle install"
GEM_SEED_ENABLED=1 bundle install
echo "Killing Rack"
kill $RACKUP_PID
PLUGIN_DEST_DIR=plugins_final bundle exec ruby ../lib/bsw_tech/jenkins_gem/bundler_copy.rb
