#!/bin/bash

trap "quit" SIGINT
trap "quit" SIGQUIT

# Kill the baby!
trap "kill_rsync" SIGCHLD

#
trap "pauza_cycle" SIGUSR1
trap "pauza" SIGSTOP
trap "resume" SIGCONT

CONF=/etc/rsync-get-backup
BACKUP_DIR=/backup
if -f [ /etc/rsync-get-backup.conf ]
	then
		source /etc/rsync-get-backup.conf
fi

DATE='date +%Y-%m-%d|%H:%M:%S:'
echo "`$DATE` My PID: $$"
echo "`$DATE` To pause use: kill -SIGHUP $$"

function quit(){
	echo "`$DATE` Got SIGINIT, exiting..."
	exit 1
}

function pauza(){
	if [ "$PAUZA" = "true" ]
		then
			echo "`$DATE` It is alredy paused."
		else
			echo "`$DATE` I'll pause after $HOST:$DIR"
			PAUZA=true
	fi
}

function resume(){
	if [ "$PAUZA" = "true" ]
		then
			echo "`$DATE` Resuming..."
			PAUZA=false
		else
			echo "`$DATE` Alredy working..."
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

if [ -f $CONF/$1 ]
	then
		echo "`$DATE` I'll backup just this host: $1"
		mkdir /tmp/temp_backup_conf$$
		cp $CONF/$1 /tmp/temp_backup_conf$$
		CONF=/tmp/temp_backup_conf$$
fi

for HOST in `/bin/ls $CONF`;
	do
		for DIR in `cat $CONF/$HOST`
			do
				echo "`$DATE` Backup directory $DIR from host $HOST"
				mkdir -p $BACKUP_DIR/$HOST
				rsync --delete -az $HOST:$DIR $BACKUP_DIR/$HOST/
				EXIT_ERR=$?
				# 0 = OK
				# 24 = File changed during rsync
				if [ $EXIT_ERR -eq 0 ] || [ $EXIT_ERR -eq 24 ]
					then
						echo "`$DATE` Backup $HOST:$DIR: OK"
					else
						echo "`$DATE` Backup $HOST:$DIR: ERROR ($EXIT_ERR)"
				fi
				while [ "$PAUZA" = "true" ]
					do
						echo "`$DATE` Paused, waiting for SIGCONT to resume"
    						sleep 10
				done
		done
	done

