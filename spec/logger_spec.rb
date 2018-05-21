# frozen_string_literal: true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'simple_review_app/logger'

describe SimpleReviewApp::Logger do
  class Tmp
    include SimpleReviewApp::Logger
  end

  subject { Tmp.new }

  describe '#logger' do
    it 'logs info to stdout' do
      stdout = $stdout
      io = StringIO.new
      $stdout = io
      subject.logger.info('hello world')
      expect($stdout.string).to include('hello world')
      $stdout = stdout
    end
  end
end
