#!/bin/bash
# shellcheck disable=SC2086,SC2034

USERNAME=$(whoami)
CNODE_HOME="/opt/cardano"
CNODE_CONFIG="/opt/cardano/config"
CNODE_PORT=6000 # must match your relay node port as set in the startup command
CNODE_HOSTNAME="relay01.ageek.io"  # optional. must resolve to the IP you are requesting from
CNODE_BIN="/usr/local/bin"
CNODE_LOG_DIR="/opt/cardano/logs"
NETWORKID=$(jq -r .networkId /opt/cardano/config/testnet-shelley-genesis.json)
#CNODE_VALENCY=1   # optional for multi-IP hostnames
NWMAGIC=$(jq -r .networkMagic < /opt/cardano/config/testnet-shelley-genesis.json)
[[ "${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic $[NWMAGIC]"
[[ "${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic $[NWMAGIC]"

export PATH="${CNODE_BIN}:${PATH}"
export CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket"

blockNo=$(/usr/local/bin/cardano-cli query tip ${NETWORK_IDENTIFIER} | jq -r .block )

# Note:
# if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
# IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
if [ "${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
  T_HOSTNAME="&hostname=${CNODE_HOSTNAME}"
else
  T_HOSTNAME=''
fi

if [ ! -d ${CNODE_LOG_DIR} ]; then
  mkdir -p ${CNODE_LOG_DIR};
fi

curl -s "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&valency=${CNODE_VALENCY}&magic=${NWMAGIC}${T_HOSTNAME}" | tee -a $CNODE_LOG_DIR/topologyUpdater_lastresult.json

