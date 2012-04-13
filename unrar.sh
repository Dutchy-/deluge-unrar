#!/bin/bash

# only used for scanall()
DIRS=("/home/dutchy/torrents/completed/series" "/home/dutchy/torrents/completed/other" )
# extractlocation
# For series, this is the location that sickbeard scans
EXTRACT_DIR="extracted"
# Let's not extract other bullshit
EXTRACT_ONLY="avi|mkv|nfo|iso"
# Copy stuff, for sickbeard
COPY_SERIES="avi mkv"



log () {
	logger -t deluge-extractarchives "$@"
}

function unrar_files () {
	DIRNAME=$1

	#log "extracting to $DIRNAME/$EXTRACT_DIR"
	for l in `unrar lb "$2" | grep -Pi "$EXTRACT_ONLY"`
	do
		if [ ! -e "$DIRNAME/$EXTRACT_DIR/$l" ]
		then
			log "Extracting $l to $DIRNAME/$EXTRACT_DIR"
			#echo "unrar x -idcpq -tsm0 -n$l $2 $DIRNAME/$EXTRACT_DIR"
			unrar x -idcpq -tsm0 "-n$l" "$2" "$DIRNAME/$EXTRACT_DIR"
		else 
			log "Already extracted: $l"
		fi
	done
	log ""
}

function scanrars () {
	log "Scanning $1/$2 for rars"
	for k in `find "$1/$2" -iname "*.rar" -print0`
	do
		log "Found rar file $k"
		unrar_files "$1" "$k"
	done
}

# 
function scanfiles () {
	log "Scanning $1/$2 for: $COPY_SERIES"
	for i in $COPY_SERIES
	do
		for m in `find "$1/$2" -iname "*.$i" -print0 | grep -iv sample`
		do
			BASENAME=`basename "$m"`
			if [ ! -e "$1/$EXTRACT_DIR/$BASENAME" ]
			then
				log "Copying $m to $1/$EXTRACT_DIR"
				cp "$m" "$1/$EXTRACT_DIR"
			else
				log "Already copied: $m"
			fi
		done
	done
}


function scanfolder () {
	scanrars "$1" "$2"
	scanfiles "$1" "$2"
}

function scanall () {
	for i in "${DIRS[@]}"
	do
		for j in `ls $i`
		do
			scanfolder "$i" "$j"
		done
	done
}

# deluge hook
if [ $# -eq 3 ]
then
	TORRENTID=$1
	TORRENTNAME=$2
	TORRENTPATH=$3
	log "Starting deluge extract-hook for torrent $TORRENTID"
	# scan one torrent
	scanfolder "$TORRENTPATH" "$TORRENTNAME"
	log "Finished deluge extract-hook"

else
	log "Starting complete unrar scan"
	scanall
fi
