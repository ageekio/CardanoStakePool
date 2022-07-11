#!/bin/bash

BLOCKPRODUCING_IP=<BLOCK PRODUCER IN HERE>
BLOCKPRODUCING_PORT=6000
curl -s -o /opt/cardano/config/testnet-topology.json "https://api.clio.one/htopology/v1/fetch/?max=20&magic=1097911063&customPeers=::1|relays-new.cardano-testnet.iohkdev.io:3001:2"
