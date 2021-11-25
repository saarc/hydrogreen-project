#!/bin/bash

set -x

ver=1.0

docker exec cli peer chaincode install -n hydrogreen -v $ver -p github.com/hydrogreen/v1.0

docker exec cli peer chaincode instantiate -n hydrogreen -v $ver -C mygreen -c '{"Args":["MANAGERID","100000000"]}' -P 'AND ("Org1MSP.member")' 
sleep 3

# # peer0.org1.hydrogreen.com invoke -> ws putstate -> block 생성 
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["adduser","U101"]}'  
sleep 3
# cid, id, amount, date, place, price
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["charge","CH10001","U101","5","2021-11-25","SUWONNO1", "44000"]}'  
sleep 3
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["addmileage","U101","10000"]}' 
sleep 3
docker exec cli peer chaincode invoke -n hydrogreen -C mygreen -c '{"Args":["submileage","U101","5000"]}'
sleep 3

docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["getmileage","U101"]}'  
docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","U101"]}'
docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","ManagerIDKey"]}'
docker exec cli peer chaincode query -n hydrogreen -C mygreen -c '{"Args":["history","TotalSupplyKey"]}'


