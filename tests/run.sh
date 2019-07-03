if [[ ! -f ~/aerogram/Dockerfile ]] ; then
	echo "-err: no such file ~/aerogram/Dockerfile"
	exit 1
fi

if [[ `pgrep docker` == "" ]] ; then
	echo "-err: couldn't contact the Docker daemon - is Docker running?"
	exit 1
fi

docker-compose up -d --build