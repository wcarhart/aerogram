#!/bin/bash

trap handler SIGUSR1
shopt -s nullglob

CONTENT=""
COLOR="green"
mkdir -p ~/.aerogram

RECEIVER="${1#*=}"
IP="${2#*=}"
PORT="${3#*=}"
USER="${4#*=}"

grey() {
	printf "\033[90m$1\033[0m\n"
}
red() {
	printf "\033[91m$1\033[0m\n"
}
green() {
	printf "\033[92m$1\033[0m\n"
}
yellow() {
	printf "\033[93m$1\033[0m\n"
}
blue() {
	printf "\033[94m$1\033[0m\n"
}
pink() {
	printf "\033[95m$1\033[0m\n"
}
white() {
	printf "\033[97m$1\033[0m\n"
}
teal() {
	printf "\033[96m$1\033[0m\n"
}

handler() {
	# TODO: implement 'FROM' field
	# TODO: implement 'TIME' field (message timestamp)
	FILES=( ~/.aerogram/ready_*.txt)
	while [[ "${#FILES[@]}" -gt 0 ]] ; do
		FILE="${FILES[0]}"
		while IFS= read -r LINE ; do
		    if [[ "$LINE" == "/STARTOFMESSAGE/" ]] ; then
		    	continue
		    fi
		    if [[ "$LINE" == "/ENDOFMESSAGE/" ]] ; then
		    	break
		    fi
		    echo -ne "\033[2K"
			echo -ne "\033[E"
			red "$LINE"
			echo -ne "$CONTENT"
		done < $FILE
		FILENAME=`basename $FILE`
		mv $FILE ~/.aerogram/done"${FILENAME##ready}"
		FILES=( ~/.aerogram/ready_*.txt)
	done
}

custom_command() {
	CHANGE=0
	COMM="${CONTENT% *}"
	ARG="${CONTENT#* }"
	if [[ "$COMM" == "/color" ]] ; then
		if [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "grey" ]] ; then
			COLOR="grey"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "red" ]] ; then
			COLOR="red"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "green" ]] ; then
			COLOR="green"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "yellow" ]] ; then
			COLOR="yellow"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "blue" ]] ; then
			COLOR="blue"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "pink" ]] ; then
			COLOR="pink"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "white" ]] ; then
			COLOR="white"
			CHANGE=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "teal" ]] ; then
			COLOR="teal"
			CHANGE=1
		fi
	fi
	echo "$CHANGE $COLOR"
}

echo "Starting..."
while : ; do
	while IFS='' read -s -n 1 KEY ; do
		if [[ "$KEY" == "" ]] ; then
			# handle custom commands
			if [[ "${CONTENT:0:1}" == "/" ]] ; then
				OUTPUT=( `custom_command` )
				CHANGE="${OUTPUT[0]}"
				if [[ $CHANGE -eq 1 ]] ; then
					COLOR="${OUTPUT[1]}"
					echo -ne "\033[2K"
					echo -ne "\033[E"
					$COLOR "Changed color to $COLOR"
					CONTENT=""
				else
					echo -ne "\033[2K"
					echo -ne "\033[E"
					CONTENT=""
				fi
			# handle regular input
			else
				#TODO: implement send
				#TODO: implement spinner
				> ~/.aerogram/buffer.txt
				echo "/STARTOFMESSAGE/" > ~/.aerogram/buffer.txt
				echo "$CONTENT" >> ~/.aerogram/buffer.txt
				echo "/ENDOFMESSAGE/" >> ~/.aerogram/buffer.txt
				DATE=`date +%H-%M-%S-%Y-%m-%d`
				if [[ "$PORT" == "" ]] ; then
					scp -q ~/.aerogram/buffer.txt $USER@$IP:/home/$RECEIVER/.aerogram/new_$DATE.txt
				else
					scp -q -P $PORT ~/.aerogram/buffer.txt $USER@$IP:/home/$RECEIVER/.aerogram/new_$DATE.txt
				fi
				echo -ne "\033[2K"
				echo -ne "\033[E"
				$COLOR "$CONTENT"
				CONTENT=""
			fi
		else
			CONTENT="$CONTENT$KEY"
			echo -ne "$KEY"
		fi
	done
done
