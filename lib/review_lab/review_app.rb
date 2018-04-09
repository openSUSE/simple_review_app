require 'octokit.rb'
require 'zaru'
require 'yaml'
require 'active_model'

class ReviewApp
  include ActiveModel::Model
  attr_accessor :pull_request, :host, :project_name, :options
  attr_writer :name
  
  def deploy
    return name if File.exists?(directory)
    clone_branch
    execute_before_script
    copy_files
    update_docker_compose_file
    start_app
    name
  end
  
  def destroy
    do_in_project_directory do
      %x[docker-compose -p #{name} stop]
    end
    FileUtils.rm_rf(directory)
  end
  
  private
  
  def start_app
    do_in_project_directory do
      %x[docker-compose -p #{name} up -d]
    end
  end
  
  def clone_branch
    Dir.mkdir(directory)
    Dir.chdir(directory){
      %x[#{clone_command}]
    }
  end
  
  def copy_files
    FileUtils.cp_r(Dir[files_directory], project_directory)  
  end
  
  def files_directory
    File.join(options[:working_directory], '..', 'files/*')
  end
  
  def execute_before_script
    do_in_project_directory do
      before_scripts.each do |script|
        %x[#{script}]
      end
    end
  end
  
  def before_scripts
    options[:before_script] || []
  end
  
  def update_docker_compose_file
    compose_file = YAML.load_file(docker_compose_file_path)
    compose_file = add_traefik_frontend_rule(compose_file)
    compose_file = add_relative_url_root(compose_file)
    write_docker_compose_file(compose_file)
  end
  
  def write_docker_compose_file(compose_file)
    File.open(docker_compose_file_path, 'w') do |f|
       f.write(YAML.dump(compose_file))
     end
  end
  
  def add_relative_url_root(compose_file)
    compose_file['services']['frontend']['environment'] ||= []
    compose_file['services']['frontend']['environment'] << "RAILS_RELATIVE_URL_ROOT=/#{name}"
    compose_file
  end
  
  def add_traefik_frontend_rule(compose_file)
    compose_file['services']['frontend']['labels']['traefik.frontend.rule'] = "Host:#{host}; PathPrefix:/#{name}"
    compose_file
  end
  
  def docker_compose_file_path
    "#{project_directory}/docker-compose.yml"
  end
  
  def clone_command
    "git clone -b #{branch} --single-branch #{fork_url}"
  end
  
  def name
    @name ||= Zaru.sanitize!("#{user_login}-#{branch}").downcase
  end
  
  def fork_url
    pull_request.head.repo.clone_url
  end
  
  def user_login
    pull_request.head.user.login
  end
  
  def branch
    pull_request.head.ref
  end
  
  def directory
    File.join(options[:working_directory], name)
  end
  
  def project_directory
    File.join(directory, project_name)
  end
  
  def do_in_project_directory
    Dir.chdir(project_directory) {
      yield
    }
  end
end
