var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
        contractInstance = new web3.eth.Contract(abi, "//insert Contract Address of Deployed Contract here", {from: accounts[0]});
        console.log(contractInstance);
    });
    $("#flip_button").click(flip);  //Improve: Success alert information 
    $("#get_data_button").click(fetchAndDisplay);
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
        alert("Done!")
    })
}

function fetchAndDisplay(){
    contractInstance.methods.getBalance().call().then(function(res){
        console.log(res);
        $("owner_output").text(res[0]);     // What is wrong here?
        $("balance_output").text(res[1]);   // What is wrong here?
    })
}