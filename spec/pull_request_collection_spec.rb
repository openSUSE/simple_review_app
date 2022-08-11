# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'octokit'
require 'simple_review_app/pull_request_collection'

describe SimpleReviewApp::PullRequestCollection, vcr: true do
  let(:logger) { double }
  let(:label) { 'review-lab' }

  before do
    allow(logger).to receive(:info)
  end

  describe '#all' do
    subject do
      SimpleReviewApp::PullRequestCollection.new(
        repository: 'open-build-service',
        organization: 'ChrisBr',
        labels: label,
        client: Octokit::Client.new,
        logger:
      ).all
    end

    let(:pr_label) { subject.first.content.labels.first.name }

    it { expect(subject.length).to eq(1) }
    it { expect(pr_label).to eq(label) }
  end
end
