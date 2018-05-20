# Simple Review App

Review apps are apps which get created on the fly for open pull requests to make it easier to review. Review apps are great :smile:

## Why?

We wanted to have something lightweight to create review apps instead of maintaining e.g. a Cloud or Kubernetes. 
The simple_review_app app is only docker.
So if your app already runs with docker-compose, it is very likely that simple_review_app works already out of the box.

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
  
  # In some cases it might also be desirable to disable the comments completely.
  # config.disable_comments = false
  
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

The simple_review_app will loop over all open pull requests, checks out the pull requests with the specified label and run a docker-compose up.

To make it possible to run several apps on the same machine, the awesome [Traefik proxy](https://traefik.io/) will come to the rescue.
To make Traefik happy, you need to adapt your docker-compose file a little bit.
In simplest case, it can look like this:

```
version: '2'
services:
  db:
    image: openbuildservice/mariadb
  frontend:
    image: openbuildservice/frontend
    networks:
    - traefik
    - default
    volumes:
    - ".:/obs"
    environment:
    - RAILS_RELATIVE_URL_ROOT={{ root_url }}
    labels:
      traefik.frontend.rule: {{ traefik_frontend_rule }}
      traefik.docker.network: traefik_default
      traefik.port: '3000'
    depends_on:
    - db
networks:
  traefik:
    external:
      name: traefik_default
```

In this docker-compose file, we have two containers running: the database and the frontend app.
The interesting part is the frontend app.

To make it possible to work with Traefik, it needs to be in the same network as the Traefik container.
This can be done by adding the networks section and adding the ``traefik`` and ``default`` (otherwise the container can not reach the db anymore) networks.

Second, it needs to be possible to run the app in a subfolder, for Rails application you need to pass ``RAILS_RELATIVE_URL_ROOT={{ root_url }}`` to the container (root_url will get replaced by simple_review_app).
For rails application, you might need to adapt the ``config.ru`` file to setup the routing.

Last but not least, we need to add the labels section to the container.

In your docker-compose file you can make use of these variables which get assigned by simple_review_app:
- root_url: the URL of the review app, e.g. /my-pull-request-42
- traefik_frontend_rule: Overwrites the Traefik frontend rule to e.g. ``Host:localhost; PathPrefix:/my-pull-request-42``. This would make the review app available at ``localhost/my-pull-request-42`` (https://docs.traefik.io/configuration/backends/docker/#on-containers)

A full example can be found in this repository: https://github.com/ChrisBr/obs-review-apps

## Dependencies

As said, this gem makes heavily use of docker and docker-compose, so you need to install these dependencies before you can use simple_review_app:

Install docker, docker-compose and add your user to the docker group. Finally start and enable the docker service:

```
zypper in docker docker-compose
usermod -a -G docker review-lab
systemctl enable docker
systemctl start docker
```

## Thanks

This gem wouldn't be possible without [docker](https://www.docker.com/), [docker-compose](https://docs.docker.com/compose/) and [Traefik](https://traefik.io/).
