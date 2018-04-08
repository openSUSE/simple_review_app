require 'yaml'
require './lib/review_lab/review_app'
require './lib/review_lab/pull_request_collection'

class ReviewLab
  def run
    self.running_apps = []
    create_working_directory
    deploy_review_apps
    destroy_review_apps
  end

  attr_accessor :running_apps

  private

  def deploy_review_apps
    pull_requests.each do |pull_request|
      deploy_review_app(pull_request)
    end
  end
  
  def deploy_review_app(pull_request)
    self.running_apps << ReviewApp.new(pull_request: pull_request, host: config['host'], options: review_app_options).deploy
  end
  
  def review_app_options
    { working_directory: working_directory, before_script: config['before_script'] }
  end
  
  def destroy_review_apps
    orphaned_apps.each do |dir|
      options = { working_directory: working_directory }
      ReviewApp.new(name: dir, options: options).destroy
    end
  end
  
  def config
    @config ||= YAML.load_file(config_path)
  end
  
  def config_path
    File.join(File.dirname(__FILE__), '..', 'config.yml').freeze
  end
  
  def working_directory
    File.join(File.dirname(__FILE__), '..', 'review_apps').freeze
  end
  
  def create_working_directory
    return if File.exists?(working_directory)
    Dir.mkdir(working_directory)
  end

  def all_apps
    Dir.chdir(working_directory) {
      Dir.glob('*').select { |f| File.directory?(f) }
    }
  end

  def orphaned_apps
    (all_apps - running_apps)
  end
  
  def pull_requests
    PullRequestCollection.new(
      username: config['github_username'], 
      password: config['github_password'],
      organization: config['github_organization'],
      repository: config['github_repository'], 
      labels: config['github_labels']
    ).all
  end
end
