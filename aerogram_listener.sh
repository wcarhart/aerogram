#!/bin/bash

shopt -s nullglob
while : ; do
	PID=`pgrep -f aerogram_renderer.sh`
	if [[ $PID == "" ]] ; then
		continue
	fi
	FILES=( ~/.aerogram/new_*.txt )
	if [[ "${#FILES[@]}" -gt 0 ]] ; then
		for FILE in "${FILES[@]}" ; do
			FOUND=0
			while [[ $FOUND -eq 0 ]] ; do
				while IFS= read -r LINE ; do
				    if [[ "$LINE" == "/ENDOFMESSAGE/" ]] ; then
				    	FOUND=1
				    fi
				done < $FILE
			done
			mv $FILE ~/.aerogram/ready"${FILE##*new}"
			kill -SIGUSR1 $PID
		done
	fi
done
