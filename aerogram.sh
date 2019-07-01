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
	exit 1
fi
if [[ ! -f aerogram_renderer.sh ]] ; then
	echo "aerogram: err: no such file 'aerogram_renderer.sh'"
	exit 1
fi
PERM=`$STAT -c "%a" aerogram_renderer.sh`
if [[ "${PERM:0:1}" != "7" ]] ; then
	echo "aerogram: err: incorrect file permissions on 'aerogram_renderer.sh'"
	exit 1
fi

mkdir -p ~/.aerogram

./aerogram_listener.sh &
./aerogram_renderer.sh
