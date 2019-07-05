#!/bin/bash

trap cleanup EXIT

# cleanup trap
cleanup() {
	for PID in `pgrep -f aerogram_listener.sh` ; do kill -9 $PID > /dev/null 2>&1 ; done
	for PID in `pgrep -f aerogram_renderer.sh` ; do kill -9 $PID > /dev/null 2>&1 ; done
}

# usage helper
usage() {
	cat << EndOfUsage
Send messages to remote users via SSH/SCP

Usage:
  aerogram.sh RECEIVER@IP [-h/--help] [-p/--port PORT] [-u/--user USER] [-r/--recv] [-d/--disp NAME]

Required arguments:
  RECEIVER        - the username for the user you'd like to chat with
  IP              - the IP address for the user you'd like to chat with

Optional arguments:
  -h, --help      - display this help menu and exit
  -p, --port PORT - the port to use (default is '22')
  -u, --user USER - the name of the user you'd like to ssh login as 
                    (default is '`whoami`')
  -r, --recv      - run aerogram in receive-only mode, where you can only receive messages
  -d, --disp NAME - your display name (default is `whoami`)

Notes:
  - both you and the RECEIVER must be running aerogram.sh
  - you don't need to know RECEIVER's ssh credentials, but you do need to know
    USER's ssh credentials
  - it is HIGHLY recommended that you add your SSH keys to your RECEIVER so you
    don't have to type in your password every time you send a message
EndOfUsage
}

# validate inputs
if [[ $# -lt 1 ]] ; then
	usage
	exit 1
fi

# TODO: resolve aliases in 'address.book'

# check if the first argument is to run in receive only mode
RECV=0
if [[ "$1" == "-r" || "$1" == "--recv" ]] ; then
	RECV=1
elif [[ "$1" != *@* ]] ; then
	echo "aerogram: err: incorrect argument format, must be in form RECEIVER@IP"
	echo "  Use 'aerogram.sh -h' for more options"
	exit 1
fi

# parse rest of command line arguments
RECEIVER="${1%@*}"
IP="${1#*@}"
PORT=""
USER=`whoami`
DISP=""
shift

while [[ $# -gt 0 ]] ; do
	KEY="$1"
	case $KEY in
		-h|--help)
			usage
			;;
		-p|--port)
			PORT="$2"
			shift
			shift
			;;
		-u|--user)
			USER="$2"
			shift
			shift
			;;
		-r|--recv)
			RECV=1
			shift
			;;
		-d|--disp)
			DISP="$2"
			shift
			shift
			;;
		*)
			echo "aerogram: err: unknown argument $1"
			usage
			;;
	esac
done

# set up receiver home path
PTH=/home/$USER
if [[ "$USER" == "root" ]] ; then
	PTH=/root
fi

# reset local working directory
shopt -s nullglob
mkdir -p ~/.aerogram
chmod 777 ~/.aerogram
FILES=( ~/.aerogram/new_* )
if [[ "${#FILES[@]}" -gt 0 ]] ; then
	for FILE in "${FILES[@]}" ; do rm $FILE ; done
fi

echo "Validating your environment..."

# validate shell and operating system
OS=`uname -s`
if [[ "`basename $SHELL`" != "bash" ]] ; then
	echo "aerogram: err: not supported for this shell"
	exit 1
fi
if [[ ! -f /bin/bash ]] && [[ ! -L /bin/bash ]] ; then
	echo "aerogram: err: could not find Bash at /bin/bash"
	echo "Use the following to link Bash to /bin/bash, and then try again:"
	echo "  ln -sf bash /bin/bash"
	exit 1
fi
if [[ $OS != "Linux" && $OS != "Darwin" ]] ; then
	echo "aerogram: err: not supported for this operating system"
	exit 1
fi

printf "\033[A\033[30C\033[92mDONE\033[0m\n"
echo "Validating receiver's environment..."

# validate that receiver is available
if [[ $RECV -eq 0 ]] ; then
	if [[ `command -v nc` == "" ]] ; then
		echo "aerogram: err: netcat is not installed"
		echo "  aerogram needs netcat to check network connections"
		echo "  Please install netcat with 'brew/apt-get/yum install nc'"
		exit 1
	fi

	PARG=""
	if [[ "$PORT" != "" ]] ; then
		PARG="-p $PORT"
	fi

	# Perform the following checks:
	#   1. Is ssh available for the receiving machine?
	#   2. Can the recipient user receive ssh requests on the receiving machine?
	#   3. Does the directory ~/.aerogram exist on the receiving machine?
	#   4. Is the directory ~/.aerogram readable and writeable on the receiving machine?

	# check #1
	nc -z $IP "${PORT:-22}" > /dev/null 2>&1
	if [[ $? -ne 0 ]] ; then
		echo "aerogram: err: ssh refused for IP $IP for port $PORT"
		exit 1
	fi

	# check #2
	ssh -q $USER@$IP $PARG exit
	if [[ $? -ne 0 ]] ; then
		echo "aerogram: err: ssh is not available for $USER on $IP"
		echo "  Please ensure that $USER can ssh into $IP successfully"
		exit 1
	fi

	# check #3
	ssh $USER@$IP $PARG [ -d $PTH/.aerogram ]
	if [[ $? -ne 0 ]] ; then
		echo "aerogram: err: no such directory $IP:$PTH/.aerogram"
		echo "  Please ask $RECEIVER to run 'mkdir -p $PTH/.aerogram'"
		echo "  This often occurs the first time you run aerogram.sh"
		exit 1
	fi

	# check #4
	if [[ `ssh $USER@$IP uname -s` == "Linux" ]] ; then
		PERM=`ssh $USER@$IP $PARG stat -c "%a" $PTH/.aerogram`
	else
		PERM=`ssh $USER@$IP $PARG gstat -c "%a" $PTH/.aerogram`
	fi
	if [[ "${PERM:2}" != "7" && "${PERM:2}" != "6" ]] ; then
		echo "aerogram: err: $RECEIVER@$IP:$PTH/.aerogram does not have write permissions"
		echo "  Please ask $RECEIVER to run 'chmod o+w $PTH/.aerogram'"
		exit 1
	fi
fi

printf "\033[A\033[36C\033[92mDONE\033[0m\n"
echo "Validating dependencies..."

# set commands based on OS
if [[ $OS == "Darwin" ]] ; then
	STAT="gstat"
else
	STAT="stat"
fi

# check dependency shell script permissions
if [[ ! -f aerogram_listener.sh ]] ; then
	echo "aerogram: err: no such file 'aerogram_listener.sh'"
	exit 1
fi
PERM=`$STAT -c "%a" aerogram_listener.sh`
if [[ "${PERM:0:1}" != "7" ]] ; then
	echo "aerogram: err: incorrect file permissions on 'aerogram_listener.sh'"
	echo "  Please run 'chmod +x aerogram_listener.sh' to fix"
	exit 1
fi
if [[ ! -f aerogram_renderer.sh ]] ; then
	echo "aerogram: err: no such file 'aerogram_renderer.sh'"
	exit 1
fi
PERM=`$STAT -c "%a" aerogram_renderer.sh`
if [[ "${PERM:0:1}" != "7" ]] ; then
	echo "aerogram: err: incorrect file permissions on 'aerogram_renderer.sh'"
	echo "  Please run 'chmod +x aerogram_renderer.sh' to fix"
	exit 1
fi

printf "\033[A\033[26C\033[92mDONE\033[0m\n"

# run listener in background and renderer in foreground
./aerogram_listener.sh &
echo "Initializing aerogram..."
./aerogram_renderer.sh "RECEIVER=$RECEIVER" "IP=$IP" "PORT=$PORT" "USER=$USER" "RECV=$RECV" "DISP=$DISP"
