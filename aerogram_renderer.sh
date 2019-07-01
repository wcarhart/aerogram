#!/bin/bash

trap handler SIGUSR1

green() {
	printf "\033[92m$1\033[0m\n"
}
red() {
	printf "\033[91m$1\033[0m\n"
}

handler() {
	if [[ -f ~/.aerogram/content.txt ]] ; then
		while IFS= read -r LINE; do
		    red "$LINE"
		done < ~/.aerogram/content.txt
	fi
}

echo "Starting..."
while : ; do
	echo -ne "> "
	read CONTENT
	green $CONTENT
done
