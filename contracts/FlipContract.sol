import"./Ownable.sol";
import"./provableAPI.sol";

pragma solidity 0.5.12;

contract FlipContract is Ownable, usingProvable {

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;    //Why unit256? Isn't uint8 enought?
    uint256 public latestNumber;                        //Why unit256? Isn't uint8 enought?
    uint bet;
    address payable player;

    event betTaken(address user, uint bet, bool);
    event funded(address contractOwner, uint funding);
    event LogNewProvableQuery(string description);
    event generatedRandomNumber(uint256 randomNumber);

    constructor() public {
        provable_setProof(proofType_Ledger);
        flip();                                       //Update to new random number
    }

    modifier costs(uint cost){
        require(msg.value >= cost, "The minimum bet is 0.01 Ether");
        _;
    }
    // Oracle Callback Function of the flip() function
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            /**
             * @notice  The proof verification has failed! Handle this case
             *          however you see fit.
             */
        }
        else {
            /**
             *
             * @notice  The proof verifiction has passed!
             *
             *          Let's convert the random bytes received from the query
             *          to a `uint256`.
             *
             *          To do so, We define the variable `ceiling`, where
             *          `ceiling - 1` is the highest `uint256` we want to get.
             *          The variable `ceiling` should never be greater than:
             *          `(MAX_INT_FROM_BYTE ^ NUM_RANDOM_BYTES_REQUESTED) - 1`.
             *
             *          By hashing the random bytes and casting them to a
             *          `uint256` we can then modulo that number by our ceiling
             *          in order to get a random number within the desired
             *          range of [0, ceiling - 1].
             *
             */
            // ceiling = (MAX_INT_FROM_BYTE ** NUM_RANDOM_BYTES_REQUESTED) - 1;
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 100; //Random number between 0 - 100
            latestNumber = randomNumber;
            bool success;

            if(randomNumber <= 50){
                success = false;
            }
            else if(randomNumber >= 50){
                success = true;
                player.transfer(bet * 2);
            }
            emit betTaken(player, bet, success);
            //return success;
            emit generatedRandomNumber(randomNumber);
        }
    }
    // Function to simulate coin flip 50/50 randomnes
    function flip() public payable {
        //require(msg.value <= address(this).balance / 2, "Jackpot is the max bet you can make");

        bet = msg.value;
        player = msg.sender;

        uint256 QUERY_EXECUTION_DELAY = 0;      //config: execution delay (0 for no delay)
        uint256 GAS_FOR_CALLBACK = 200000;      //config: gas fee for calling __callback function (200000 is standard)
        provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);     //function to query a random number, it will call the __callback function
        emit LogNewProvableQuery("Provable query was sent, standing by for answer...");
    }

/*    // Function to simulate coin flip 50/50 randomnes
    function flip() public payable returns(bool){
        //require(address(this).balance >= msg.value, "The contract hasn't enought funds");
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
        emit betTaken(msg.sender, msg.value, success);
        return success;
    }
*/
    // Function to Withdraw Funds
    function withdrawAll() public onlyContractOwner returns(uint){
        msg.sender.transfer(address(this).balance);
        assert(address(this).balance == 0);
        return address(this).balance;
    }
    // Function to get the Balance of the Contract
    function getBalance() public view returns (address, uint) {
        return (address(this), address(this).balance);
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