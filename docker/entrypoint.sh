#!/bin/sh
set -e

# Default values
export PORT=4000
export RPC_HOST="localhost"
export RPC_PORT=9904
export RPC_USER="testnet"
export RPC_PASSWD="testnet"

# Parse the commandline arguments
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -p|--port)
    export PORT="$2"
    shift # past argument
    ;;
    -h|--rpc-host)
    export RPC_HOST="$2"
    shift # past argument
    ;;
    -rp|--rpc-port)
    export RPC_PORT="$2"
    shift # past argument
    ;;
    -usr|--rpc-user)
    export RPC_USER="$2"
    shift # past argument
    ;;
    -pwd|--rpc-password)
    export RPC_PASSWD="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo ""
echo "### Starting Mercator ###"
echo PORT            = "${PORT}"
echo RPC HOST        = "${RPC_HOST}"
echo RPC PORT        = "${RPC_PORT}"
echo RPC USER        = "${RPC_USER}"
echo RPC PASSWD      = "***"
echo ""

# Run as unprivileged user
su-exec $USER $HOME/$REL_NAME/bin/$REL_NAME foreground & wait
