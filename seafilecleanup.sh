#!/bin/bash

# display usage if the script is not run as root user
        if [[ $USER != "root" ]]; then
                echo "This script must be run as root user!"
                exit 1
        fi

echo "Super User detected!!"

read -p "Press [ENTER] to start the procedure, this will stop the seafile server!!"

# stop the server
echo Stopping the Seafile-Server...
#/opt/seafile/haiwen/seafile-server-latest/seafile.sh stop
#/opt/seafile/haiwen/seafile-server-latest/seahub.sh stop
/etc/init.d/seafile-server stop

echo Giving the server some time....
sleep 5

# run the cleanup
echo Cleanup running...
sudo -u seafile /opt/seafile/haiwen/seafile-server-latest/seaf-gc.sh
echo "Cleaning temp files..."
rm /opt/seafile/haiwen/seafile-data/httptemp/*

echo Giving the server some time....
sleep 3

# start the server again
echo Starting the Seafile-Server...
#/opt/seafile/haiwen/seafile-server-latest/seafile.sh start
#/opt/seafile/haiwen/seafile-server-latest/seahub.sh start-fastcgi
/etc/init.d/seafile-server start

echo All done!


