#!/bin/bash

# messages move through the following states:
#  new --> ready --> done
#    new:   This message has just arrived. The listener sends a signal to the 
#           renderer and moves this message to the 'ready' state.
#    ready: This message has be received but not processed. The renderer has
#           received a signal to process this message, but has not completed
#           processing yet. Once the message is processed, it will be moved to
#           the 'done' state.
#    done:  This message has been rendered by the renderer and has completed
#           its sending proccess.

# main listen loop
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
