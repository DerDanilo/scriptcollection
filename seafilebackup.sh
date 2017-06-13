#!/bin/bash

# Local CIFS Mount, has to be defined in FSTAB and needs to be mounted for the backup
CIFSMOUNTDIR=/mnt/backup
# This file has to be created prior to execution of the script "touch /MY/CIFS/PATH/mounted.status"
CIFSSTATUSFILE=$CIFSMOUNTDIR/mounted.status

# Where is Seafile installed? - Program files and data
SOURCEFOLDER=/opt/seafile/haiwen/
# Where should the backup files be stored? - Should be a subfolder to have rsync throw an error if not mounted properly
TARGETBACKUPDIR=/mnt/backup/seafile

SQLUSER="seafile"
SQLPASSWORD="XXXXXXXXXXXXX"
SQLHOST="localhost"

# Don't touch if not necessary 
LOCALBACKUPDIR=$SOURCEFOLDER"backup_db_and_config"
LOCALBACKUPTEMPDIR=$LOCALBACKUPDIR/latest

########################
# functions start here #
########################

function cifsinfo {
echo "CIFS usage" $1
df -h $CIFSMOUNTDIR 
}

function stopseafile {
echo "Stopping Seafile Server..."
/etc/init.d/seafile-server stop
}

function startseafile {
echo "Start Seafile Server..."
/etc/init.d/seafile-server start
}

function createbackupdir {
# Create directorie
if [ ! -d $LOCALBACKUPDIR ]
  then
  echo "Creating Backup directory " $LOCALBACKUPDIR "..."
  mkdir $LOCALBACKUPDIR
fi
# Create sub directorie for sql dumb
if [ ! -d $LOCALBACKUPTEMPDIR ]
  then
  echo "Creating Backup subdirectory " $LOCALBACKUPTEMPDIR "..."
  mkdir $LOCALBACKUPTEMPDIR
fi
}

function runbackup {
echo "Check if target dir exists: " $TARGETBACKUPDIR
if [ -e $TARGETBACKUPDIR ]; then
	echo "Backup dir exists."
	cifsinfo "before backup:"
	echo "Starting rsync backup...."
	echo "/usr/bin/rsync -rlptDh --delete --stats " $SOURCEFOLDER " " $TARGETBACKUPDIR
	/usr/bin/rsync -rlptDh --delete --stats $SOURCEFOLDER $TARGETBACKUPDIR
	cifsinfo "after backup:"
else
	echo "# E R R O R ! - Dir does not exist, check mount path and permission! - " $TARGETBACKUPDIR
fi
}

function checktargetandrunbackup {
# check if cif share is mounted, remount if required and run rsync
echo "Check if target exist (CIFS mount)...."
if [ -e $CIFSSTATUSFILE ]; then
	echo "Cifs share mounted."
	runbackup
else
	echo "Cifs not mounted, remounting..."
	umount $CIFSMOUNTDIR
	mount $CIFSMOUNTDIR
	echo "Cifs share remount command executed."
	runbackup
fi
}


function sqldump {
echo "Creating DB dumbs..."
mysqldump -h $SQLHOST -u $SQLUSER -p$SQLPASSWORD ccnet-db > $LOCALBACKUPTEMPDIR/ccnet-db_sqlbkp_`date +"%Y%m%d"`.sql
mysqldump -h $SQLHOST -u $SQLUSER -p$SQLPASSWORD seafile-db > $LOCALBACKUPTEMPDIR/seafile-db_sqlbkp_`date +"%Y%m%d"`.sql
mysqldump -h $SQLHOST -u $SQLUSER -p$SQLPASSWORD seahub-db > $LOCALBACKUPTEMPDIR/seahub-db_sqlbkp_`date +"%Y%m%d"`.sql
}

function sqlconfigbackup {
if [ -d "/etc/mysql" ]; then
	echo "SQL config backup..."
	cp -r /etc/mysql/ $LOCALBACKUPTEMPDIR/
fi
}

function webserverbackup {
	echo "Copy nginx config files..."
	cp -r /etc/nginx/ $LOCALBACKUPTEMPDIR/
	cp -r /usr/share/nginx/html/ $LOCALBACKUPTEMPDIR/
}

function autostartbackup {
	echo "Copy autostart scripts..."
	cp /etc/init.d/seafile-server $LOCALBACKUPTEMPDIR/ 
}

function seafile_app_and_config {
	echo "Copy Seafile Server app and config..."
	cp -r $SOURCEFOLDER"ccnet"/ $LOCALBACKUPTEMPDIR/
	cp -r $SOURCEFOLDER"conf"/ $LOCALBACKUPTEMPDIR/
	cp -r $SOURCEFOLDER"customSCRIPTS"/ $LOCALBACKUPTEMPDIR/
	cp -r $SOURCEFOLDER"seahub-data"/ $LOCALBACKUPTEMPDIR/
	cp -r $SOURCEFOLDER"seafile-server-latest"/ $LOCALBACKUPTEMPDIR/
}

function somemagic {
	# looking for 14 days old backups and delete them - NOT the last 14 backups, 14 days back BY DATE !!
	echo "Deleteting backup files older than 14 days..."
	find $LOCALBACKUPDIR -mtime +14 -type f -exec rm {} \;

	# Remove Backup files if created today already
	rm $LOCALBACKUPDIR/backup_`date +"%Y%m%d"`.tar.gz

	# Compress files
	echo "Compress backup files..."
	tar -Pczf $LOCALBACKUPDIR/backup_`date +"%Y%m%d"`.tar.gz -C $LOCALBACKUPTEMPDIR .

	# Remove directory with temp files (after they have been compressed)
	echo "Remove temp files..."
	rm -rf $LOCALBACKUPTEMPDIR

	#fix permission for all backup files
	echo "Fixing permission..."
	chown -R seafile.nogroup $LOCALBACKUPDIR/
}

function dependencies {
	function check_prog {
		if hash $1 2>/dev/null; then
			echo $1 "installed."
		else
			echo $1 "not installed. Trying to install."
			apt-get update; apt-get install $1 -y
		fi
	}
	for p in rsync ; do check_prog $p ; done
}

###### Script start

echo "### SIMPLE SEAFILE BACKUP SCRIPT ###"
echo "Let's get started..."
dependencies
createbackupdir
stopseafile
sqldump
sqlconfigbackup
webserverbackup
autostartbackup
seafile_app_and_config
startseafile
somemagic
checktargetandrunbackup

echo "All done!"





