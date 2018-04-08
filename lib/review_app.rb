require 'octokit.rb'
require 'zaru'
require 'yaml'
require 'active_model'

class ReviewApp
  include ActiveModel::Model
  attr_accessor :pull_request, :host, :options
  attr_writer :name
  
  def deploy
    return name if File.exists?(directory)
    clone_branch
    copy_files
    execute_before_script
    set_host
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
    FileUtils.cp_r(Dir['files/*'], project_directory)  
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
  
  def set_host
    compose_file = YAML.load_file(docker_compose_file_path)
    compose_file['services']['frontend']['labels']['traefik.frontend.rule'] = "Host:#{name}.#{host}"
    File.open(docker_compose_file_path, 'w') do |f|
       f.write(YAML.dump(compose_file))
     end
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
  
  def project_name
    pull_request.base.repo.name
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
