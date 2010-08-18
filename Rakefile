Dir['tasks/*.rake'].each { |file| load(file) }

require 'rubygems'
require 'bundler'

Bundler.setup

GithubGem::RakeTasks.new(:gem)
task :default => [:spec]
