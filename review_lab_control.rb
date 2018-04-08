require './lib/review_lab.rb'
require 'daemons'

review_lab = ReviewLab.new

Daemons.run_proc('./lib/review_lab.rb') do
  loop do
    review_lab.run
    puts 'Sleeping for 60 seconds...'
    sleep(60)
  end
end
