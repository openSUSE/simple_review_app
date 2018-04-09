# frozen_string_literal: true

require './lib/review_lab.rb'
require 'daemons'

Daemons.run_proc('./lib/review_lab.rb') do
  loop do
    ReviewLab.run
    sleep(60)
  end
end
