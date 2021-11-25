package main

// 외부모듈 포함
import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// 체인코드 클레스 구조체정의
type SmartContract struct {
}


// 1. WS 
// ID,  ID, 충전량, 충전 일시, 장소, 금액, 마일리지
// 2. 주요 기능
// Init - 현대 충전소 ID와 정보, 인증기관(환경부)의 정보
// charge - 
// 	현대충전소-> 충전소ID, 사용자ID:nil, 충전량, 충전일시, 장소, 금액
// 	사용자 -> 충전소ID, 사용자ID, 충전량, 충전일시, 장소, 금액
// history - ID (사용자 ID, 충전소ID)
// addMileage - ID, 마일리지양
// subMileage - ID, 마일리지양


// paper world state 구조체정의
type Charge struct { // 발행인, 어음일련번호, 소유인, 발행일, 만기일, 액면가, 상태
	ID 		string `json:"id"` 	// 충전소 ID, 유저 아이디
	Camount string `json:"amount"`
	Cdate  	string `json:"date"`
	Cplace  string `json:"place"`
	Price  	string `json:"price"`
}

type User struct {
	ID 		string 	`json:"id"`
	Mileage int		`json:"mileage"`
}

const managerID_KEY 	= "ManagerIDKey"
const totalSupply_KEY	= "TotalSupplyKey"

// Init 함수 정의 체인코드 배포/업그래이드시에 초기화 함수
func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	// (TODO) 현대자동차 ID
	// (TODO) 인증기관(환경부)의 정보
	// (TODO) 마일리지 총량 TOTALMILEAGE, 100000000

	args := APIstub.GetStringArgs()
	if len(args) != 2 {
		return shim.Error("Invalid Arguments. ManagerID and TotalSupply are required")
	}
	totalM, _ := strconv.Atoi(args[1])

	_ = APIstub.PutState(totalSupply_KEY, []byte(strconv.Itoa(totalM)))

	manager := User{args[0], totalM}
	managerAsBytes, _ := json.Marshal(manager)
	_ = APIstub.PutState(managerID_KEY, managerAsBytes )

	return shim.Success(nil)
}

// Invoke 함수 정의 체인코드 수행 (인도서피어가 papercontract 수행-invoke, query)
func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "charge" {
		return s.charge(APIstub, args)
	} else if function == "adduser" {
		return s.adduser(APIstub, args)
	} else if function == "history" {
		return s.history(APIstub, args)
	} else if function == "addmileage" {
		return s.addmileage(APIstub, args)
	} else if function == "submileage" {
	 	return s.submileage(APIstub, args)
	} else if function == "getmileage" {
		return s.getmileage(APIstub, args)
    }

	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) charge(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 6 { // cid, id, amount, date, place, price
		return shim.Error("Incorrect number of arguments. Expecting 6")
	}
	// 충전ID조회
	chargeAsBytes, _ := APIstub.GetState(args[0]) // WS 조회
	if chargeAsBytes != nil {
		shim.Error("Duplicated charge ID")
	}

	// userID조회
	userAsBytes, _ := APIstub.GetState(args[1]) // WS 조회
	if userAsBytes == nil {
		shim.Error("Invalid user ID")
	}

	charge := Charge{args[1],args[2],args[3],args[4],args[5]}

	chargeAsBytes, _ = json.Marshal(charge)
	APIstub.PutState(args[0], chargeAsBytes)

	// (TODO) 마일리지 추가 price 비율로 user 에 마일리지를 추가
	// userAsByte -> Unmarshal 한다음 수정하고 다시 marshal -> putstate user

	return shim.Success(nil)
}

func (s *SmartContract) adduser(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 1 { // user id
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	userAsBytes, _ := APIstub.GetState(args[1]) // WS 조회
	if userAsBytes != nil {
		shim.Error("Duplicate User ID")
	}
	user := User{args[0], 0}

	userAsBytes, _ = json.Marshal(user)
	APIstub.PutState(args[0], userAsBytes)

	return shim.Success(nil)
}

func (s *SmartContract) addmileage(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 2 { // user id, 차감마일리지
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// MANAGER 마일리지 조회
	managerAsBytes, _ := APIstub.GetState(managerID_KEY) // WS 조회
	if managerAsBytes == nil {
		shim.Error("Invaild Manager ID")
	}
	manager := User{}
	// UNMARSHAL 해서 수정
	_ = json.Unmarshal(managerAsBytes, &manager)

	// USER 마일리지 조회
	userAsBytes, _ := APIstub.GetState(args[0]) // WS 조회
	if userAsBytes == nil {
		shim.Error("Invaild User ID")
	}
	user := User{}
	// UNMARSHAL 해서 수정
	_ = json.Unmarshal(userAsBytes, &user)

	mamount, _ := strconv.Atoi(args[1])
	if manager.Mileage < mamount {
		shim.Error("Not enough mileage in manager account")
	}
	user.Mileage += mamount
	manager.Mileage -= mamount

	// MARSHAL -> PUTSTATE
	userAsBytes, _ = json.Marshal(user)
	APIstub.PutState(args[0], userAsBytes)

	managerAsBytes, _ = json.Marshal(manager)
	APIstub.PutState(managerID_KEY, managerAsBytes)

	return shim.Success(nil)
}
func (s *SmartContract) submileage(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 2 { // user id, 차감마일리지
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// MANAGER 마일리지 조회
	managerAsBytes, _ := APIstub.GetState(managerID_KEY) // WS 조회
	if managerAsBytes == nil {
		shim.Error("Invaild Manager ID")
	}
	manager := User{}
	// UNMARSHAL 해서 수정
	_ = json.Unmarshal(managerAsBytes, &manager)

	// USER 마일리지 조회
	userAsBytes, _ := APIstub.GetState(args[0]) // WS 조회
	if userAsBytes == nil {
		shim.Error("Invaild User ID")
	}
	user := User{}
	// UNMARSHAL 해서 수정
	_ = json.Unmarshal(userAsBytes, &user)

	mamount, _ := strconv.Atoi(args[1])
	if user.Mileage < mamount {
		shim.Error("Not enough mileage in user account")
	}
	user.Mileage -= mamount
	manager.Mileage += mamount

	// MARSHAL -> PUTSTATE
	userAsBytes, _ = json.Marshal(user)
	APIstub.PutState(args[0], userAsBytes)

	managerAsBytes, _ = json.Marshal(manager)
	APIstub.PutState(managerID_KEY, managerAsBytes)

	return shim.Success(nil)
}
func (s *SmartContract) getmileage(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 { // user id
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	// USER조회
	userAsBytes, _ := APIstub.GetState(args[0]) // WS 조회
	if userAsBytes == nil {
		shim.Error("Invaild User ID")
	}
	return shim.Success(userAsBytes)
}

// history 함수 정의 <- chaincode/marbles -> gethistoryforkey
func (t *SmartContract) history(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	key := args[0]

	fmt.Printf("- start getHistoryForKey: %s\n", key)

	resultsIterator, err := stub.GetHistoryForKey(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing historic values for the marble
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"TxId\":")
		buffer.WriteString("\"")
		buffer.WriteString(response.TxId)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Value\":")
		// if it was a delete operation on given key, then we need to set the
		//corresponding value null. Else, we will write the response.Value
		//as-is (as the Value itself a JSON marble)
		if response.IsDelete {
			buffer.WriteString("null")
		} else {
			buffer.WriteString(string(response.Value))
		}

		buffer.WriteString(", \"Timestamp\":")
		buffer.WriteString("\"")
		buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
		buffer.WriteString("\"")

		buffer.WriteString(", \"IsDelete\":")
		buffer.WriteString("\"")
		buffer.WriteString(strconv.FormatBool(response.IsDelete))
		buffer.WriteString("\"")

		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- getHistoryForKey returning:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}

// main 함수 정의
func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
