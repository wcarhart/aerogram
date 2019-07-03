#!/bin/bash

trap handler SIGUSR1
shopt -s nullglob

CONTENT=""
COLOR="green"

RECEIVER="${1#*=}"
IP="${2#*=}"
PORT="${3#*=}"
USER="${4#*=}"
RECV="${5#*=}"
DISPLAYNAME="${6#*=}"
if [[ "$DISPLAYNAME" == "" ]] ; then
	DISPLAYNAME=`whoami`
fi

PTH=/home/$RECEIVER
if [[ "$USER" == "root" ]] ; then
	PTH=/root
fi

colorprint() {
	for ARG in $@ ; do 
		printf "$ARG "
	done
	printf "\n"
}

grey() {
	printf "\033[90m$1\033[0m"
}
red() {
	printf "\033[91m$1\033[0m"
}
green() {
	printf "\033[92m$1\033[0m"
}
yellow() {
	printf "\033[93m$1\033[0m"
}
blue() {
	printf "\033[94m$1\033[0m"
}
pink() {
	printf "\033[95m$1\033[0m"
}
teal() {
	printf "\033[96m$1\033[0m"
}
white() {
	printf "\033[97m$1\033[0m"
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
		    if [[ "$LINE" == /FROM/* ]] ; then
		    	FROMUSER="${LINE#/FROM/ *}"
		    	continue
		    fi
		    echo -ne "\033[2K"
			echo -ne "\033[E"
			FILENAME=`basename $FILE`
			colorprint '[' "\b${FILENAME:6:2}:${FILENAME:9:2}" '\b]' `red "$FROMUSER"`: "$LINE"
			echo -ne "$CONTENT"
		done < $FILE
		FILENAME=`basename $FILE`
		mv $FILE ~/.aerogram/done"${FILENAME##ready}"
		FILES=( ~/.aerogram/ready_*.txt)
	done
}

custom_command() {
	# currently supported custom commands: /color, /exit
	# return values:
	#   RET_VAL=0 --> return (do nothing)
	#   RET_VAL=1 --> change color to RET_ARG
	#   RET_VAL=2 --> exit
	RET_VAL=0
	COMM="${CONTENT% *}"
	ARG="${CONTENT#* }"
	if [[ "$COMM" == "/color" ]] ; then
		if [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "grey" ]] ; then
			RET_ARG="grey"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "red" ]] ; then
			RET_ARG="red"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "green" ]] ; then
			RET_ARG="green"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "yellow" ]] ; then
			RET_ARG="yellow"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "blue" ]] ; then
			RET_ARG="blue"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "pink" ]] ; then
			RET_ARG="pink"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "white" ]] ; then
			RET_ARG="white"
			RET_VAL=1
		elif [[ `echo "$ARG" | tr '[:upper:]' '[:lower:]'` == "teal" ]] ; then
			RET_ARG="teal"
			RET_VAL=1
		fi
	elif [[ "$COMM" == "/exit" ]] ; then
		RET_VAL=2
	fi
	echo "$RET_VAL $RET_ARG"
}

echo "Starting..."
while : ; do
	while IFS='' read -s -n 1 KEY ; do
		if [[ "$KEY" == "" ]] ; then
			# handle custom commands
			if [[ "${CONTENT:0:1}" == "/" ]] ; then
				OUTPUT=( `custom_command` )
				RET_VAL="${OUTPUT[0]}"
				if [[ $RET_VAL -eq 1 ]] ; then
					COLOR="${OUTPUT[1]}"
					echo -ne "\033[2K"
					echo -ne "\033[E"
					colorprint `$COLOR "Changed color to $COLOR"`
					CONTENT=""
				elif [[ $RET_VAL -eq 2 ]] ; then
					echo
					exit 0
				else
					echo -ne "\033[2K"
					echo -ne "\033[E"
					CONTENT=""
				fi
			# handle regular input
			else
				> ~/.aerogram/buffer.txt
				echo "/STARTOFMESSAGE/" > ~/.aerogram/buffer.txt
				echo "/FROM/ $DISPLAYNAME" >> ~/.aerogram/buffer.txt
				echo "$CONTENT" >> ~/.aerogram/buffer.txt
				echo "/ENDOFMESSAGE/" >> ~/.aerogram/buffer.txt
				DATE=`date +%H-%M-%S-%Y-%m-%d`
				if [[ $RECV -eq 0 ]] ; then
					if [[ "$PORT" == "" ]] ; then
						echo -ne "  "
						scp -q ~/.aerogram/buffer.txt $USER@$IP:$PTH/.aerogram/new_$DATE.txt & \
						while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done; done
						
					else
						echo -n "  "
						scp -q -P $PORT ~/.aerogram/buffer.txt $USER@$IP:$PTH/.aerogram/new_$DATE.txt & \
						while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done; done
					fi
				fi
				echo -ne "\033[2K"
				echo -ne "\033[E"
				colorprint '[' "\b`date +%H:%M`" '\b]' `$COLOR $DISPLAYNAME`: "$CONTENT"
				CONTENT=""
			fi
		else
			CONTENT="$CONTENT$KEY"
			echo -ne "$KEY"
		fi
	done
done
