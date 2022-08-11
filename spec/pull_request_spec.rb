# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'octokit'
require 'simple_review_app/pull_request'

describe SimpleReviewApp::PullRequest, vcr: true do
  let(:client) { Octokit::Client.new }
  let(:content) { client.pull_request('ChrisBr/open-build-service', 8) }
  let(:logger) { double }

  before do
    allow(logger).to receive(:info)
  end

  subject do
    SimpleReviewApp::PullRequest.new(
      content:,
      full_repository_name: 'ChrisBr/open-build-service',
      logger:
    )
  end

  describe '#number' do
    it { expect(subject.number).to eq(8) }
  end

  describe '#user_login' do
    it { expect(subject.user_login).to eq('ChrisBr') }
  end

  describe '#branch' do
    it { expect(subject.branch).to eq('bar') }
  end

  describe '#clone' do
    let(:testdir) { 'spec/tmp/pull_request_spec' }

    after do
      FileUtils.rm_rf testdir
    end

    it 'executes the clone command inside the testdir' do
      allow(subject).to receive(:clone_command).and_return('touch works')
      subject.clone(testdir)
      expect(File.exist?(File.join(testdir, 'works'))).to be_truthy
    end

    it 'executes the correct clone command' do
      clone_command = 'git clone -b bar --depth 1 --single-branch https://github.com/ChrisBr/open-build-service.git'
      expect(subject).to receive(:capture2e_with_logs).with(clone_command)
      subject.clone(testdir)
    end
  end

  describe '#update' do
    let(:testdir) { 'spec/tmp/pull_request_spec' }
    let(:project_dir) { File.join(testdir, 'open-build-service') }

    before do
      FileUtils.mkdir_p project_dir
    end

    after do
      FileUtils.rm_rf project_dir
      FileUtils.rm_rf testdir
    end

    it 'updates the pull request directory' do
      expect(subject).to receive(:capture2e_with_logs).with('git fetch --all')
      expect(subject).to receive(:capture2e_with_logs).with('git reset origin/bar --hard')
      allow(subject).to receive(:cloned_sha).and_return('different')
      subject.update(testdir)
    end

    it 'does not update the pull request directory' do
      expect(subject).not_to receive(:capture2e_with_logs).with('git fetch --all')
      expect(subject).not_to receive(:capture2e_with_logs).with('git reset origin/bar --hard')
      allow(subject).to receive(:cloned_sha).and_return(subject.content.head.sha)
      subject.update(testdir)
    end
  end
end
