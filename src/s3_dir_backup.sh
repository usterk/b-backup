#!/bin/bash

trap "quit" SIGINT
trap "quit" SIGQUIT

# Kill the baby!
trap "kill_rsync" SIGCHLD

#
trap "pauza_cycle" SIGUSR1
trap "pauza" SIGSTOP
trap "resume" SIGCONT

CONF=/etc/b-backup/s3-dir-backup.conf
DIR_LIST_FILE=/etc/b-backup/s3-dir-backup.list
TMP=/
BUCKET_NAME=b-backup

DATE='date +%Y-%m-%d|%H:%M:%S:'

if [ -f $CONF ]
	then
		source $CONF
fi

TEMP_DIR=$TMP/s3-dir-backup$$
mkdir -p $TEMP_DIR
function log(){
	echo "`$DATE` $*"
}

DATE='date +%Y-%m-%d|%H:%M:%S:'
log "My PID: $$"
log "To pause use: kill -SIGHUP $$"

function quit(){
	log "Got SIGINIT, exiting..."
	rm -rf $TEMP_DIR
	exit 1
}

function pauza(){
	if [ "$PAUZA" = "true" ]
		then
			log "It is alredy paused."
		else
			log "I'll pause after $HOST:$DIR"
			PAUZA=true
	fi
}

function resume(){
	if [ "$PAUZA" = "true" ]
		then
			log "Resuming..."
			PAUZA=false
		else
			log "Alredy working..."
	fi
}


function pauza_cycle(){
	echo "`$DATE` I got SIGUSR1"
	if [ "$PAUZA" = "true" ]
		then
			resume
		else
			pauza
	fi
}

for DIR in `cat $DIR_LIST_FILE`;
	do
		log "Backup directory $DIR"
		FILEDATE=$(date +'%Y-%m-%d_%H%M%S')
		BACKUP_FILE=$TEMP_DIR/$(basename $DIR)-$FILEDATE.tar.gz
		tar -czf $BACKUP_FILE $DIR
		EXIT_ERR=$?
		# 0 = OK
		if [ $EXIT_ERR -eq 0 ]
			then
				s3cmd put --multipart-chunk-size-mb=100 --progress --recursive --reduced-redundancy $BACKUP_FILE s3://$BUCKET_NAME > /dev/null
				S3ERR=$?
				if [ $S3ERR -eq 0 ]
					then
						log "Backup $DIR: OK"
					else
						log "Backup $DIR: s3cmd ERROR ($S3ERR)"
			else
				log "Backup $DIR: ERROR ($EXIT_ERR)"
		fi
		rm $BACKUP_FILE
		while [ "$PAUZA" = "true" ]
			do
				log "Paused, waiting for SIGCONT to resume"
    				sleep 10
		done
		done
	done
rm -rf $TEMP_DIR
