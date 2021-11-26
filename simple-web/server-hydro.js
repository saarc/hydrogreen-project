// ExpressJS Setup
const express = require('express');
const app = express();
var bodyParser = require('body-parser');

// Hyperledger Bridge
const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const ccpPath = path.resolve(__dirname,'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

// Constants
const PORT = 3000;
const HOST = '0.0.0.0';

// use static file
app.use(express.static(path.join(__dirname, 'views')));

// configure app to use body-parser
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// main page routing
app.get('/', (req, res)=>{
    res.sendFile(__dirname + '/index-hydro.html');
});


// 사용자추가 라우팅
app.post('/user', async(req, res)=>{
    const customerid = req.body.customerid;
 
    try {
        console.log(`user post routing - ${customerid}`);

        cc_call('adduser', [customerid], res)

    }
    catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
    }

});

// 마일리지 라우팅
app.post('/mileage', async(req, res)=>{
    const customerid = req.body.customerid;
    const amount = req.body.amount;
    const mode = req.body.mode;
 
    try {
        console.log(`mileage post routing - ${customerid}`);

        if(mode == "add")
            cc_call('addmileage', [customerid, amount], res);
        else if(mode == "sub")
            cc_call('submileage', [customerid, amount], res);

    }
    catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
    }

});

// 충전이력생성 라우팅
app.post('/charge', async(req, res)=>{
    
    //ncid, ncuid, ndate, namount, nprice, nplace
    const ncid = req.body.ncid;
    const ncuid = req.body.ncuid;
    const ndate = req.body.ndate;
    const namount = req.body.namount;
    const nprice = req.body.nprice;
    const nplace = req.body.nplace;

    try {
        console.log(`charge post routing - ${ncid}`);

        cc_call('charge', [ncid,ncuid,namount,ndate,nplace,nprice], res)

    }
    catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
    }

});

// history
app.get('/history', async(req, res)=>{

    try {
        const id = req.query.pid;
        console.log(`history routing - ${id}`);

        cc_call('history', [id], res)

    }
    catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
    }
});

async function cc_call(fn_name, args, res){


    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    const userExists = await wallet.exists('user1');
    if (!userExists) {
        console.log(`cc_call`);
        console.log('An identity for the user "user1" does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }
    const gateway = new Gateway();
    await gateway.connect(ccpPath, { wallet, identity: 'user1', discovery: { enabled: true, asLocalhost: true } });
    const network = await gateway.getNetwork('mygreen');
    const contract = network.getContract('hydrogreen');

    var result;

    if(fn_name == 'adduser'){
        result = await contract.submitTransaction('adduser', args[0]);
        const myobj = {result: "success"}
        res.status(200).json(myobj)
    }else if(fn_name == 'addmileage'){
        result = await contract.submitTransaction('addmileage', args[0], args[1]);
        const myobj = {result: "success"}
        res.status(200).json(myobj)
    }else if(fn_name == 'submileage'){
        result = await contract.submitTransaction('submileage', args[0], args[1]);
        const myobj = {result: "success"}
        res.status(200).json(myobj)
    }else if(fn_name == 'charge'){
        result = await contract.submitTransaction('charge', args[0],args[1],args[2],args[3],args[4],args[5]);
        const myobj = {result: "success"}
        res.status(200).json(myobj)
    }else if(fn_name == 'history'){
        result = await contract.evaluateTransaction('history', args[0]);
        const myobj = JSON.parse(result)
        res.status(200).json(myobj)
    }else{
        result = 'not supported function'
    }

    gateway.disconnect();

    return ;
}

// server start
app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);