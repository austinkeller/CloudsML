#!/usr/bin/env sh

set -e

### Helper functions

try_find_open_port()
{
	local __out__host_port=$1
	local DEFAULT_HOST_PORT=80
	local LOWERPORT
	local UPPERPORT
	read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
	local MINPORT=49152
	local MAXPORT=65535
	LOWERPORT=$(( LOWERPORT > MINPORT ? LOWERPORT : MINPORT))
	UPPERPORT=$(( UPPERPORT < MAXPORT ? UPPERPORT : MAXPORT))
	echo "Searching port range ${LOWERPORT}-${UPPERPORT} for an available port..."
	local count=$(( MAXPORT - MINPORT ))
	while [ $count -gt 0 ]
	do
		PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
		ss -lpn | grep -q ":$PORT " || break
		count=$(( count - 1 ))
	done
	eval $__out__host_port=$(( count == 0 ? DEFAULT_HOST_PORT : PORT ))
}

### Main

image=clouds-ml
platform=jupyter

if [ $platform = "jupyter" ]; then
	port=8888
	home_dir=/home/jovyan
else
	port=8787
	home_dir=/home/rstudio
fi

echo ""
echo ""
echo "#### Figuring out networking configuration"
echo ""

try_find_open_port HOST_PORT
echo "Using port $HOST_PORT"

echo ""
echo ""
echo "#### Building Docker image"
echo ""

docker build -t $image .
image_id=$(docker run -d --rm -p $HOST_PORT:$port -v "$(pwd):$home_dir/work" -v "$HOME/.aws:$home_dir/.aws" $image)
kill_container_script=kill-container-${image_id}.sh
echo '#!/bin/bash' > $kill_container_script
echo "docker kill $image_id" >> $kill_container_script

echo "Waiting for container to start..."
sleep 8
url_attributes=$(docker container logs $image_id --tail 1 2>&1 | grep -o \?.*)
token=$(echo $url_attributes | grep -o token=.* | cut -d"=" -f2)

echo ""
echo ""
echo "#### Instructions for end-user"
echo ""
echo "Notebook server running in container $image_id"
echo "Use 'bash kill-container-${image_id}.sh' to kill it."
echo ""
echo "If the notebook did not open automatically, point your browser to http://localhost:${HOST_PORT}${url_attributes}"
echo "Login with:"
echo "token: $token"

echo ""
echo ""
echo "#### Attempting to open browser"
echo ""
xdg-open "http://localhost:${HOST_PORT}${url_attributes}"

