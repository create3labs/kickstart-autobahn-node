#!/bin/bash
# (C) CREATE3 Labs, Inc. 2022-present
# All rights reserved
# Licensed under MIT License (see LICENSE)
# Autobahn Node installation script: install and set up Nodes on supported Linux distributions
# using CREATE3 Labs repositories.

set -eEuox pipefail;

( docker compose version 2>&1 || docker-compose version 2>&1 ) | grep -q v2 || { echo "docker compose v2 is required to run this script Please install it via https://docs.docker.com/compose/install/linux/#install-using-the-repository"; exit 1; }

VERSION=1.0.0
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

function on_read_error() {
  printf "Timed out or input EOF reached, assuming 'No'\n"
  # yn="n"
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


# OS/Distro Detection
# Try lsb_release, fallback with /etc/issue then uname command
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE|Rocky|AlmaLinux)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)

if [ "$DISTRIBUTION" = "Darwin" ]; then
    printf "%s" "\033[31mThis script does not support installing on the Mac.";
    exit 1;

elif [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
    OS="Debian"
elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ] || [ "$DISTRIBUTION" == "Rocky" ] || [ "$DISTRIBUTION" == "AlmaLinux" ]; then
    OS="RedHat"
# Some newer distros like Amazon may not have a redhat-release file
elif [ -f /etc/system-release ] || [ "$DISTRIBUTION" == "Amazon" ]; then
    OS="RedHat"
# Arista is based off of Fedora14/18 but do not have /etc/redhat-release
elif [ -f /etc/Eos-release ] || [ "$DISTRIBUTION" == "Arista" ]; then
    OS="RedHat"
# openSUSE and SUSE use /etc/SuSE-release or /etc/os-release
elif [ -f /etc/SuSE-release ] || [ "$DISTRIBUTION" == "SUSE" ] || [ "$DISTRIBUTION" == "openSUSE" ]; then
    OS="SUSE"
fi

# User detection. Needs to be user with uid 1000
# @todo: Change to be any other user. Check https://github.com/create3labs/autobahn-nodes/blob/main/docker/docker-compose.yaml Line 10
if [ "$(echo "$UID")" != "1000" ]; then
    printf "%s" "You have to install with the user owning uid/gid 1000 for now.";
fi

### Start
printf "%s" "Creating DATADIR ${DATA_DIR}...";
if [ ! -d "${DATA_DIR}" ]; then
  printf "%s" "Does not exist. Creating data dir..."
  mkdir -p ${DATA_DIR};
fi

printf "%s" "Creating CONFIG_DIR ${CONFIG_DIR}...";
if [ ! -d "${CONFIG_DIR}"  ]; then
  printf "%s" "Does not exist. Creating config dir...";
  mkdir -p ${CONFIG_DIR};
fi

#### Loading and extracting the Repo
curl -L $REPO_URL | tar xzv -C ./
cd autobahn-nodes-$VERSION;

#### executing the init script
