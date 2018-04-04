require 'octokit.rb'
require 'yaml'
require './lib/review_app'

config = YAML.load_file('config.yml')

if config['github_username'] && config['github_password']
  Octokit.configure do |c|
    c.login = config['github_username']
    c.password = config['github_password']
  end
end

BASEDIR = File.join("#{File.dirname(__FILE__)}", "review_apps").freeze
unless File.exists?(BASEDIR)
  Dir.mkdir(BASEDIR)
end

def pull_requests(repository, label)
  issues = Octokit.list_issues(repository, labels: label)
  issues.find_all { |i| i.pull_request }
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
pull_requests(config['github_repository'], config['github_label']).each do |pull_request|
  options = { repository: config['github_repository'], working_directory: BASEDIR }
  running_apps << ReviewApp.new(pull_request_number: pull_request.number, options: options).deploy
end

orphaned_apps(running_apps).each do |dir|
  options = { working_directory: BASEDIR }
  ReviewApp.new(name: dir, options: options).destroy
end
