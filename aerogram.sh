#!/bin/bash

#trap cleanup EXIT

# cleanup trap
cleanup() {
	if [[ -d ~/.aerogram ]] ; then
		rm -rf ~/.aerogram
	fi
	kill -9 `pgrep -f aerogram_listener.sh`
	kill -9 `pgrep -f aerogram_renderer.sh`
}

# detect os type
ostype() {
    OS=`uname -s`
    case "${OS}" in
        Linux*)     MACHINE=Linux   ;;
        Darwin*)    MACHINE=MacOS   ;;
        CYGWIN*)    MACHINE=Cygwin  ;;
        MINGW*)     MACHINE=MinGw   ;;
        *)          MACHINE=UNKNOWN ;;
    esac
    echo "$MACHINE"
}

# usage helper
usage() {
	cat << EndOfUsage
Send messages to remote users via SSH/SCP

Usage:
  aerogram.sh RECEIVER@IP [-h/--help] [-p/--port PORT] [-u/--user USER]

Required arguments:
  RECEIVER        - the username for the user you'd like to chat with
  IP              - the IP address for the user you'd like to chat with

Optional arguments:
  -h, --help      - display this help menu and exit
  -p, --port PORT - the port to use (default is '22')
  -u, --user USER - the name of the user you'd like to login as 
                    (default is '`whoami`')

Notes:
  - both you and the RECEIVER must be running aerogram.sh
  - it is HIGHLY recommended that you add your SSH keys to your RECEIVER so you
    don't have to type in your password every time you send a message
EndOfUsage
}

# validate inputs
if [[ $# -lt 1 ]] ; then
	usage
	exit 1
fi

if [[ "$1" != *@* ]] ; then
	echo "aerogram: err: incorrect argument format, must be in form RECEIVER@IP"
	echo "  Use 'aerogram.sh -h' for more options"
	exit 1
fi

RECEIVER="${1%@*}"
IP="${1#*@}"
PORT=""
USER=`whoami`
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
		*)
			echo "aerogram: err: unknown argument $1"
			usage
			;;
	esac
done

PTH=/home/$RECEIVER
if [[ "$USER" == "root" ]] ; then
	PTH=/root
fi

mkdir -p ~/.aerogram
chmod 777 ~/.aerogram

# validate environment
OS=`ostype`
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
if [[ $OS != "Linux" && $OS != "MacOS" ]] ; then
	echo "aerogram: err: not supported for this operating system"
	exit 1
fi

if [[ "$PORT" == "" ]] ; then
	PERM=`ssh $USER@$IP stat -c "%a" $PTH/.aerogram`
else
	PERM=`ssh $USER@$IP -p $PORT stat -c "%a" $PTH/.aerogram`
fi
if [[ "$PERM" == "" ]] ; then
	echo "aerogram: err: ssh/scp refused for $USER on ${PORT:-22}"
	echo "  Please ensure that ssh/scp is available for $USER on port ${PORT:-22}"
	exit 1
fi
if [[ "${PERM:2}" != "7" && "${PERM:2}" != "6" ]] ; then
	echo "aerogram: err: $RECEIVER@$IP:$PTH/.aerogram does not have write permissions"
	echo "  Please ask $RECEIVER to run 'chmod o+w $PTH/.aerogram'"
	exit 1
fi

if [[ $OS == "MacOS" ]] ; then
	READLINK="greadlink"
	STAT="gstat"
else
	READLINK="readlink"
	STAT="stat"
fi

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

./aerogram_listener.sh &
./aerogram_renderer.sh "RECEIVER=$RECEIVER" "IP=$IP" "PORT=$PORT" "USER=$USER"
