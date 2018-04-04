# Installation

1) Install docker, docker-compose and ruby, add user to group docker and start docker service

```
zypper in docker docker-compose ruby 
usermod -a -G docker review-lab
systemctl start docker
```

2) Start traefik reverse proxy

```
cd traefik && docker-compose up
```
