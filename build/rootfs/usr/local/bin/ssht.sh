#!/usr/bin/env bash

set -e

PORT="3000"


function usage() {
    echo "usage: $0 [-i IDENTITY_FILE] [-p PORT] HOST"
    exit 1
}

declare -a ARGS

if [ "$#" = "0" ]; then
	echo
	echo "missing required positional argument HOST"
	echo
	usage
fi

while getopts "p:i:" o; do
    case "$o" in
    p)
        PORT="$OPTARG"
        ;;
    i)
        ARGS+=("-i ${OPTARG}")
        ;;
    *)
        usage
        ;;
    esac
done

EXISTING_TUNNEL=$(ps aux | grep "ssh -D ${PORT}" | grep -v grep | awk '{print $2}')

if [ -n "$EXISTING_TUNNEL" ]; then
	echo "killing existing SSH tunnel (PID: $EXISTING_TUNNEL)"
	kill -9 $EXISTING_TUNNEL
fi

ssh -D "$PORT" -q -C -Nf "${ARGS[@]}" "${@:$OPTIND:1}"

if [ $? -eq 0 ]; then
    echo "tunnel successfully established"
else
    echo "failed to establish SSH tunnel"
    exit 1
fi
