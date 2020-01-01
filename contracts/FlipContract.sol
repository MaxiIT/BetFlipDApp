import"./Ownable.sol";

pragma solidity 0.5.12;

contract FlipContract is Ownable {

    uint public ContractBalance;

    event bet(address user, uint bet, bool);
    event funded(address owner, uint funding);


    modifier costs(uint cost){
        require(msg.value >= cost, "The minimum bet is 0.01 Ether");
        _;
    }
    // Function to simulate coin flip 50/50 randomnes
    function flip() public payable costs(0.01 ether) returns(bool){
        require(address(this).balance >= msg.value, "The contract hasn't enought funds");
        bool success;
        if(now % 2 == 0){
            ContractBalance += msg.value;
            success = false;
        }
        else if(now % 2 == 1){
            ContractBalance -= msg.value;
            msg.sender.transfer(msg.value * 2);
            success = true;
        }
        //assert(ContractBalance == address(this).balance);
        emit bet(msg.sender, msg.value, success);
        return success;
    }
    // Function to Withdraw Funds
    function withdrawAll() public onlyContractOwner returns(uint){
        msg.sender.transfer(address(this).balance);
        assert(address(this).balance == 0);
        return address(this).balance;
    }
    // Function to get the Balance of the Contract
    function getBalance() public view returns (address, uint, uint) {
        return (address(this), address(this).balance, ContractBalance);
    }
    // Fund the Contract
    function fundContract() public payable onlyContractOwner returns(uint){
        require(msg.value != 0);
        //ContractBalance += msg.value;
        emit funded(msg.sender, msg.value);
        //assert(ContractBalance == address(this).balance);
        return msg.value;
    }

}