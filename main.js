var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
        contractInstance = new web3.eth.Contract(abi, "0xB46543971bd3DB0ad13dEbD245c0c8515D562488", {from: accounts[0]});
        console.log(contractInstance);
    });
    $("#flip_button").click(flip);
    $("#get_data_button").click(fetchAndDisplay);
    $("#fund_contract_button").click(fundContract);
    $("#withdraw_button").click(withdrawAll);
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
        if(receipt.events.betTaken.returnValues[2] === false){
            alert("You lost " + bet + " Ether!");
        }
        else if(receipt.events.betTaken.returnValues[2] === true){
            alert("You won " + bet + " Ether!");
        }
    })
}

function fetchAndDisplay(){
    contractInstance.methods.getBalance().call().then(function(res){
        $("#jackpot_output").text(web3.utils.fromWei(res[1], "ether") + " Ether");
    })
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