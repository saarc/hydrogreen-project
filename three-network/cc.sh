#!/bin/bash

# 설치 1 -> cli -> peer0.org1.reshop.com
docker exec cli peer chaincode install -n papercontract -v 0.9 -p github.com/papercontract 
# linux /home/bstudent/fabric-samples/chaincode/papercontract -> cli /opt/gopath/src/github.com/papercontract

docker exec  cli peer chaincode list --installed # 설치된 체인코드 쿼리 -> ID부여된 설치 체인코드이름 버전

# 설치 2 -> cli -> peer0.org2.reshop.com
docker exec -e "CORE_PEER_ADDRESS=peer0.org2.reshop.com:8051" -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.reshop.com/users/Admin@org2.reshop.com/msp" cli peer chaincode install -n papercontract -v 0.9 -p github.com/papercontract

docker exec -e "CORE_PEER_ADDRESS=peer0.org2.reshop.com:8051" -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.reshop.com/users/Admin@org2.reshop.com/msp" cli peer chaincode list --installed

# 배포 peer0.org1.reshop.com  -> dev-papercontract 인도서 피어 컨테이너가 생성, 커미터 피어 couchdb mychannel_papercontract 테이블이생성
docker exec cli peer chaincode instantiate -n papercontract -v 0.9 -C mychannel -c '{"Args":[]}' -P 'AND ("Org1MSP.member","Org2MSP.member")' 
# 체인코드 같은 이름으로 배포 -> upgrade

sleep 3

# 배포 확인 
docker exec cli peer chaincode list --instantiated -C mychannel

# peer0.org1.reshop.com invoke -> ws putstate -> block 생성 
docker exec cli peer chaincode invoke -n papercontract -C mychannel -c '{"Args":["issue","MagnetoCorp","00021","2021-9-8","2021-12-31","1000000"]}'  --peerAddresses peer0.org1.reshop.com:7051 --peerAddresses peer0.org2.reshop.com:8051
sleep 3 # configtx.yaml batch time = 2s

# peer0.org1.reshop.com invoke -> ws putstate -> block 생성 
docker exec cli peer chaincode invoke -n papercontract -C mychannel -c '{"Args":["buy","00021","MagnetoCorp","DigiBank","950000"]}' --peerAddresses peer0.org1.reshop.com:7051 --peerAddresses peer0.org2.reshop.com:8051
sleep 3

# peer0.org1.reshop.com invoke -> ws putstate -> block 생성 
docker exec cli peer chaincode invoke -n papercontract -C mychannel -c '{"Args":["redeem","00021","DigiBank","MagnetoCorp"]}' --peerAddresses peer0.org1.reshop.com:7051 --peerAddresses peer0.org2.reshop.com:8051 
sleep 3

# peer0.org1.reshop.com query -> ws getstate -> block 생성 되지않음
docker exec cli peer chaincode query -n papercontract -C mychannel -c '{"Args":["history","00021"]}'


