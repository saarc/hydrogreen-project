#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

export CA1_KEY=$(ls crypto-config/peerOrganizations/org1.hydrogreen.com/ca/ | grep _sk)
export CA2_KEY=$(ls crypto-config/peerOrganizations/org2.hydrogreen.com/ca/ | grep _sk)
export CA3_KEY=$(ls crypto-config/peerOrganizations/org2.hydrogreen.com/ca/ | grep _sk)

docker-compose -f docker-compose.yml down

# docker-compose -> 컨테이터수행 및 net_basic 네트워크 생성
docker-compose -f docker-compose.yml up -d ca.org1.hydrogreen.com ca.org2.hydrogreen.com orderer.hydrogreen.com peer0.org1.hydrogreen.com  peer0.org2.hydrogreen.com peer0.org3.hydrogreen.com couchdb1 couchdb2 couchdb3 cli
docker ps -a
docker network ls
# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel -> mygreen.block cli working dir 복사
docker exec cli peer channel create -o orderer.hydrogreen.com:7050 -c mygreen -f /etc/hyperledger/configtx/channel.tx
# clie workding dir (/etc/hyperledger/configtx/) mygreen.block

# Join peer0.org1.hydrogreen.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.hydrogreen.com/msp" peer0.org1.hydrogreen.com peer channel join -b /etc/hyperledger/configtx/mygreen.block

sleep 3

# Join peer0.org2.hydrogreen.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.hydrogreen.com/msp" peer0.org2.hydrogreen.com peer channel join -b /etc/hyperledger/configtx/mygreen.block

sleep 3

# Join peer0.org2.hydrogreen.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.hydrogreen.com/msp" peer0.org3.hydrogreen.com peer channel join -b /etc/hyperledger/configtx/mygreen.block

sleep 3

# anchor ORG1 mygreen update
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.hydrogreen.com/msp" peer0.org1.hydrogreen.com peer channel update -f /etc/hyperledger/configtx/Org1MSPanchors.tx -c mygreen -o orderer.hydrogreen.com:7050
# anchor ORG2 mygreen update
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.hydrogreen.com/msp" peer0.org2.hydrogreen.com peer channel update -f /etc/hyperledger/configtx/Org2MSPanchors.tx -c mygreen -o orderer.hydrogreen.com:7050
docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.hydrogreen.com/msp" peer0.org3.hydrogreen.com peer channel update -f /etc/hyperledger/configtx/Org3MSPanchors.tx -c mygreen -o orderer.hydrogreen.com:7050
