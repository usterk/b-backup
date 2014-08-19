#!/bin/bash
s3cmd_compress(){
	TO_SEND=$1
	if [ -z "$TEMP_DIR" ]
		then
			log "Templorary directory variable is empty."
			return 1
	fi
	if [ ! -d $TEMP_DIR ]
		then
			log "Templorary directory does not exist"
	fi
	BACKUP_FILE=$TEMP_DIR/$(basename $TO_SEND)-$FILEDATE.tar.gz
	tar -czf $BACKUP_FILE $TO_SEND
}
s3cmd_put(){
	TO_SEND=$1
	if [ ! -e ${TO_SEND} ]
		then
			log "File ${TO_SEND} does not exist"
			return 1
	fi
	FILEDATE=$(date +'%Y-%m-%d_%H%M%S')
	log "Backing up $TO_SEND"
	s3cmd_compress ${TO_SEND}
	EXIT_ERR=$?
	# 0 = OK
	if [ $EXIT_ERR -eq 0 ]
		then
			if [ -f $BACKUP_FILE ]
				then
					s3cmd put --progress --recursive --reduced-redundancy $BACKUP_FILE s3://$BUCKET_NAME > /dev/null
					S3ERR=$?
					if [ $S3ERR -eq 0 ]
						then
							log "Backup $TO_SEND: OK"
						else
							log "Backup $TO_SEND: s3cmd ERROR ($S3ERR)"
							return 1
					fi
				else
					log "There is no BACKUP_FILE=$BACKUP_FILE"
			fi
		else
			log "Backup $TO_SEND: compression ERROR ($EXIT_ERR)"
			return 1
	fi
	rm $BACKUP_FILE
}