# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'simple_review_app/docker_compose_file'
require 'fileutils'

describe SimpleReviewApp::DockerComposeFile do
  subject { docker_compose_file }

  let(:filename) { 'spec-docker-compose.yml' }
  let(:dir) { 'spec/fixtures/' }
  let(:path) { File.join(dir, filename) }
  let(:host) { '39.40.41.42' }
  let(:app_name) { 'vanilla' }
  let(:docker_compose_file) { SimpleReviewApp::DockerComposeFile.new(path: path, app_name: app_name, host: host) }

  before do
    Dir.chdir(dir) do
      FileUtils.cp 'docker-compose.yml', filename
    end
  end

  after do
    Dir.chdir(dir) do
      FileUtils.rm filename
    end
  end

  describe '#update' do
    it 'does update set the root_url' do
      expect(subject.update.content).to include("RAILS_RELATIVE_URL_ROOT=/#{app_name}")
    end

    it 'does update set the traefik_frontend_rule' do
      expect(subject.update.content).to include("Host:#{host}; PathPrefix:/#{app_name}")
    end
  end
end
