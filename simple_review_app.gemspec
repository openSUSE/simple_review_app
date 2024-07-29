# frozen_string_literal: true

require 'date'

Gem::Specification.new do |s|
  s.name        = 'simple_review_app'
  s.version     = '0.0.0'
  s.summary     = 'Create review apps based on github pull requests'
  s.description = 'Create reivew apps based on github pull requests and your docker-compose configuration'
  s.authors     = ['Christian Bruckmayer']
  s.email       = 'christian@bruckmayer.net'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/ChrisBr/simple_review_app'
  s.license = 'MIT'

  s.add_dependency 'activemodel', '>= 5.1', '< 8.0'
  s.add_dependency 'liquid', '>= 4', '< 6'
  s.add_dependency 'octokit', '>= 4', '< 9'
  s.add_dependency 'rake', '>= 12.3', '< 14.0'
  s.add_dependency 'zaru', '>= 0.2', '< 2.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
