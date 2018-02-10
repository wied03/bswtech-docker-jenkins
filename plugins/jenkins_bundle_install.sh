#!/usr/bin/env bash
echo "Launching Rack in background"
INDEX_DIRECTORY=gem_index rackup -I ../lib ../lib/bsw_tech/jenkins_gem/config.ru &
RACKUP_PID=$!
echo "Running bundle install"
bundle install
echo "Killing Rack"
kill $RACKUP_PID

