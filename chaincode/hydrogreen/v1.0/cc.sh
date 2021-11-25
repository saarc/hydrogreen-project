#!/bin/bash

set -x

# 설치 1 -> cli -> peer0.org1.hydrogreen.com
docker exec cli peer chaincode install -n hydrogreen -v 1.0 -p github.com/hydrogreen/v1.0
# linux /home/bstudent/fabric-samples/chaincode/hydrogreen -> cli /opt/gopath/src/github.com/hydrogreen

docker exec  cli peer chaincode list --installed # 설치된 체인코드 쿼리 -> ID부여된 설치 체인코드이름 버전

# 설치 2 -> cli -> peer0.org2.hydrogreen.com
docker exec -e "CORE_PEER_ADDRESS=peer0.org2.hydrogreen.com:8051" -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.hydrogreen.com/users/Admin@org2.hydrogreen.com/msp" cli peer chaincode install -n hydrogreen -v 1.0 -p github.com/hydrogreen/v1.0

docker exec -e "CORE_PEER_ADDRESS=peer0.org2.hydrogreen.com:8051" -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.hydrogreen.com/users/Admin@org2.hydrogreen.com/msp" cli peer chaincode list --installed

# 배포 peer0.org1.hydrogreen.com  -> dev-hydrogreen 인도서 피어 컨테이너가 생성, 커미터 피어 couchdb mychannel_papercontract 테이블이생성
docker exec cli peer chaincode instantiate -n hydrogreen -v 1.0 -C mygreen -c '{"Args":["MANAGERID","100000000"]}' -P 'AND ("Org1MSP.member","Org2MSP.member")' 
# 체인코드 같은 이름으로 배포 -> upgrade

sleep 3

# 배포 확인 
docker exec cli peer chaincode list --instantiated -C mygreen

# peer0.org1.hydrogreen.com invoke -> ws putstate -> block 생성 
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["adduser","U101"]}'  --peerAddresses peer0.org1.hydrogreen.com:7051 peer0.org2.hydrogreen.com:8051
sleep 3

# 넥소 연료탱크용량 (kg/ℓ)	6.33 / 156.6
# cid, id, amount, date, place, price
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["charge","CH10001","U101","5","2021-11-25","SUWONNO1", "44000"]}'  --peerAddresses peer0.org1.hydrogreen.com:7051 peer0.org2.hydrogreen.com:8051
sleep 3

docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["addmileage","U101","10000"]}'  --peerAddresses peer0.org1.hydrogreen.com:7051 peer0.org2.hydrogreen.com:8051
sleep 3

docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["submileage","U101","5000"]}'  --peerAddresses peer0.org1.hydrogreen.com:7051 peer0.org2.hydrogreen.com:8051
sleep 3

docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["getmileage","U101"]}'  --peerAddresses peer0.org1.hydrogreen.com:7051 peer0.org2.hydrogreen.com:8051

# peer0.org1.hydrogreen.com query -> ws getstate -> block 생성 되지않음
docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","CH10001"]}'

# docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","U101"]}'
# docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","ManagerIDKey"]}'
# docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","TotalSupplyKey"]}'

