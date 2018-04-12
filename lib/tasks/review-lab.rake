# frozen_string_literal: true

require './lib/review_lab'
desc 'Deploy review apps'
task :review_lab do
  ReviewLab.run
end
