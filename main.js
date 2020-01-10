var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
        contractInstance = new web3.eth.Contract(abi, "0xff93D08C89fB0f894C3c24a3bC135fd1D975Eb0b", {from: accounts[0]});
        console.log(contractInstance);
        
    });
  
    
    web3.eth.getBalance("0xff93D08C89fB0f894C3c24a3bC135fd1D975Eb0b").then(function(result){
        $("#jackpot_output").text(web3.utils.fromWei(result, "ether") + " Ether");
    });
    
    $("#flip_button").click(flip);
    $("#fund_contract_button").click(fundContract);
    $("#withdraw_button").click(withdrawAll);
    
    
    //Event listener 3
    //contractInstance.events.generatedRandomNumber({})
    //    .on('data', event => console.log(event));
    
});

function flip(){
    var bet = $("#bet_input").val();
    var config = {
        value: web3.utils.toWei(bet,"ether")
    }
    contractInstance.methods.flip().send(config)
    .on("transactionHash", function(hash){
        console.log(hash);
    })
    .on("confirmation", function(confirmationNr){
        console.log(confirmationNr);
    })
    .on("receipt", function(receipt){
        console.log(receipt);
        /*
        if(receipt.events.betTaken.returnValues[2] === false){
            alert("You lost " + bet + " Ether!");
        }
        else if(receipt.events.betTaken.returnValues[2] === true){
            alert("You won " + bet + " Ether!");
        }
        */
    })
    
    
    
/*  Event listener 2
    contractInstance.once('betTaken', {
        filter: {player: '0xff93D08C89fB0f894C3c24a3bC135fd1D975Eb0b'}, // for test: player and contract owner are the same
        fromBlock: 7097288
    }, function(error, event){ console.log(event); });
*/
   
    //Event listener 1
    var event = contractInstance.generatedRandomNumber({}, {fromBlock:7097288, toBlock: 'latest'})
   
    event.watch(function(error, result){
        if(!error){
           console.log("Block Number: " + result.blockNumber);
        }
    });
   
}


function fundContract(){
    var fund = $("#fund_input").val();
    var config = {
        value: web3.utils.toWei(fund,"ether")
    }
    contractInstance.methods.fundContract().send(config)
    .on("transactionHash", function(hash){
        console.log(hash);
    })
    .on("confirmation", function(confirmationNr){
        console.log(confirmationNr);
    })
    .on("receipt", function(receipt){
        console.log(receipt);
    })
}

function withdrawAll(){
    contractInstance.methods.withdrawAll().send();
}