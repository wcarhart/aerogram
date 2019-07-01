#!/bin/bash

while : ; do
	if [[ ! -f ~/.aerogram/content.txt ]] ; then
		continue
	fi
	PID=`pgrep -f aerogram_renderer.sh`
	if [[ $PID == "" ]] ; then
		continue
	fi
	sleep 10
	kill -SIGUSR1 $PID
done
