#!/bin/bash
# (C) CREATE3 Labs, Inc. 2022-present
# All rights reserved
# Licensed under MIT License (see LICENSE)
# Autobahn Node installation script: install and set up Nodes on supported Linux distributions
# using CREATE3 Labs repositories.
set -eEuo pipefail;

( docker compose version 2>&1 || docker-compose version 2>&1 ) | grep -q v2 || { echo "docker compose v2 is required to run this script Please install it via https://docs.docker.com/compose/install/linux/#install-using-the-repository"; exit 1; }

VERSION=1.0.3
LOGFILE="anode-install.log"
SUPPORT_EMAIL="support@create3labs.com"

# Set up a named pipe for logging
npipe=/tmp/$$.tmp
mknod $npipe p

# Log all output to a log for error checking
tee <$npipe $LOGFILE &
exec 1>&-
exec 1>$npipe 2>&1
trap 'rm -f $npipe' EXIT

function fallback_msg(){
  printf "%s" "
If you have problems, please send an email to ${SUPPORT_EMAIL}
with the contents of ${LOGFILE} and any information you think would be
useful and we will do our very best to help you solve your problem.\n"
}

function on_error() {
    printf "%s" "\033[31m$ERROR_MESSAGE
It looks like you hit an issue when trying to install the Autobahn Node.

Troubleshooting and basic usage information are available at:

    https://docs.autobahn-network.com/\n\033[0m\n"

    if ! tty -s; then
      fallback_msg
      exit 1;
    fi
}
trap on_error ERR

echo -e "\033[34m\n* Autobahn Node install script v${VERSION}\n\033[0m"

if [ -z ${NETWORK+x} ]; then
  printf "%s" "setting network to mainnet as default..."
  NETWORK=autobahn;
fi

if [ -z ${NETWORK_ID+x} ]; then
  printf "%s" "setting network id to mainnet as default..."
  NETWORK_ID=45000;
fi

if [ -z ${NODETYPE+x} ]; then
  printf "%s" "setting nodtype to default: member..."
  NODETYPE="member";
fi

if [ -z ${BOOTNODES+x} ]; then
  printf "%s" "Please set BOOTNODES variable to a bootnode..."
  exit 1;
fi

if [ -z ${HOME+x} ]; then
  printf "%s" "Please set HOME to your home dir..."
  exit 1;
fi

if [ -z ${INTERFACE+x} ]; then
  INTERFACE=eth0;
fi

if [ -z ${REPO_URL+x} ]; then
    REPO_URL="https://github.com/create3labs/autobahn-nodes/archive/refs/tags/v${VERSION}.tar.gz";
fi

DATA_DIR=${HOME}/data/${NETWORK}
CONFIG_DIR=${HOME}/config/${NETWORK}

# User detection. Needs to be user with uid 1000
# @todo: Change to be any other user. Check https://github.com/create3labs/autobahn-nodes/blob/main/docker/docker-compose.yaml Line 10
if [ "$(echo "$UID")" != "1000" ]; then
    printf "%s" "You have to install with the user owning uid/gid 1000 for now.";
fi

### Start
printf "%s" "Creating DATADIR ${DATA_DIR}...";
if [ ! -d "${DATA_DIR}" ]; then
  printf "%s" "Does not exist. Creating data dir..."
  mkdir -p "${DATA_DIR}";
fi

printf "%s" "Creating CONFIG_DIR ${CONFIG_DIR}...";
if [ ! -d "${CONFIG_DIR}"  ]; then
  printf "%s" "Does not exist. Creating config dir...";
  mkdir -p "${CONFIG_DIR}";
fi

#### Loading and extracting the Repo
cd "${HOME}";
curl -L "${REPO_URL}" | tar xzv -C ./

#### executing the init script
cd autobahn-nodes-$VERSION;
./scripts/init.sh

#### prepare some env vars
sed -i "/BOOT_NODES.*/cBOOT_NODES=${BOOTNODES}" "${HOME}/autobahn-nodes-$VERSION/docker/nodes/.env"
sed -i "/NETWORK_ID.*/cNETWORK_ID=${NETWORK_ID}" "${HOME}/autobahn-nodes-$VERSION/docker/nodes/.env"

if [ "${NODETYPE}" == "signer" ]; then
  if [ -z "${SIGNER_ADDRESS}" ]; then
    printf "%s" "Please set SIGNER_ADDRESS as second parameter..."
    exit 1;
  fi

  if [ ! -f "${HOME}/data/password.txt" ]; then
    printf "%s" "Does not exist. Creating config dir..."
    exit 1;
  fi

  if [ ! -d "${HOME}/data/${NETWORK}/keystore" ]; then
    mkdir -p "${HOME}/data/${NETWORK}/keystore";
  fi
fi

if [ -n "${SIGNER_ADDRESS}" ]; then
  sed -i "/SIGNER_ADDRESS.*/cSIGNER_ADDRESS=${SIGNER_ADDRESS}" "${HOME}/autobahn-nodes-$VERSION/docker/nodes/signer/.env";
fi

#### Launch
cd autobahn-nodes-$VERSION;
./scripts/start.sh ${NODETYPE}