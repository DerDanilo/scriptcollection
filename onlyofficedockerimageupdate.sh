#!/bin/bash
echo "# Updating OODS - OnlyOffice docker image"
docker stop oods
docker rm oods
docker image list
echo "y" | docker image prune
docker pull onlyoffice/documentserver
docker image list
docker container list
docker run -i -t -d -p 0.0.0.0:88:80 --restart=always --name oods onlyoffice/documentserver
docker container list

# Save System upgrade
apt-get update
apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get dist-upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
reboot now
