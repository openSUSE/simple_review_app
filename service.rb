require 'octokit.rb'
require 'yaml'
require './lib/review_app'
require './lib/pull_request_collection'

config = YAML.load_file('config.yml')

BASEDIR = File.join("#{File.dirname(__FILE__)}", "review_apps").freeze
unless File.exists?(BASEDIR)
  Dir.mkdir(BASEDIR)
end

def all_apps
  Dir.chdir(BASEDIR) {
    Dir.glob('*').select { |f| File.directory?(f) }
  }
end

def orphaned_apps(running_apps)
  (all_apps - running_apps)
end

running_apps = []
collection = PullRequestCollection.new(
  username: config['github_username'], 
  password: config['github_password'], 
  repository: config['github_repository'], 
  labels: config['github_labels'])
collection.all.each do |pull_request|
  
  options = { working_directory: BASEDIR }
  running_apps << ReviewApp.new(pull_request: pull_request, options: options).deploy
end

orphaned_apps(running_apps).each do |dir|
  options = { working_directory: BASEDIR }
  ReviewApp.new(name: dir, options: options).destroy
end
