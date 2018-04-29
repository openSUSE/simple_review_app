# Simple Review App

Review apps are apps which get created on the fly for open pull requests to make it easier to review. Review apps are greate :smile:

## Getting started

To use simple_review_app you need to have Ruby, Docker and docker-compose installed. Installing simple_review_app can be done by:

```
gem 'simple_review_app'
```

Add this binary file to bin/simple_review_app and configure simple_review_app:

```
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'simple_review_app'

SimpleReviewApp.setup do |config|
  # Required configuration
  
  # Name of the github repository
  # config.github_repository = ''
  # Name of the github organization
  # simple_review_app will construct the
  # full repository name by github_organization/github_repository
  # config.github_organization = ''
  
  # Name of the docker service (obsolete)
  # config.docker_service_name = 'frontend'


  # Optional configuration
  
  # Name of the labels to identify the pull request
  # for which a review app should get created
  # Default: 'review-app'
  # config.github_labels = ''
  
  # Github credentials to query the API for pull requests
  # and to create comments
  # If you do not specify credentials, no comments will get created!
  # Please note that GitHub only allows 60 requests/hour without authorization
  # so you might want to set credentials
  # config.github_username = ''
  # config.github_password = ''
  
  # Hostname which will get set in Traefik
  # Default: localhost
  # config.host = ''

  # Filename of the docker-compose file
  # Default docker_compose.yml
  # config.docker_compose_file_name = docker_compose.yml

  # Set the data directory where the review app checkouts will get stored
  # Default: /tmp/simple_review_app/data
  # config.data_directory

  # Setup custom logger.
  # Default is to log to STDOUT
  # config.logger = Logger.new(STDOUT)

  # Directory of the overlay files
  # This directory will get copy over the git checkout
  # This is useful if you e.g. have custom configuration for review apps
  # you don't want to store in the main repository
  config.overlay_files_directory = '/home/cbruckmayer/Projects/review-lab/files'

  # Preparation steps you might need to do after the git checkout 
  # e.g. update git submodules
  # config.preparation do
  #   `git submodule init`
  #   `git submodule update`
  # end
end

SimpleReviewApp.run
```

## Dependencies

As said, this gem makes heavily use of docker and docker-compose, so you need to install these dependencies before you can use simple_review_app:

Install docker, docker-compose and add your user to the docker group. Finally start and enable the docker service:

```
zypper in docker docker-compose
usermod -a -G docker review-lab
systemctl enable docker
systemctl start docker
```
