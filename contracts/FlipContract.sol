/*  Flip contract is a smart contract which is part of a decentral web application.
    It allows the user to bet any amount of ether as long the contract is funded.
    The smart contract will call a ofchain oracle to request a random number.
    The random number will get transmitted to the smart contract through a callback.
    The user have a 50:50 chance to win (double bet amount) or lose (lose everything).
    Safty features are still require to build in.
*/

import"./Ownable.sol";
import"./provableAPI.sol";

pragma solidity 0.5.12;

contract FlipContract is Ownable, usingProvable {
    //* Variable Declaration */
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;    //Value of 1-32: But why unit256? Isn't uint8 enought? In ProvableAPI.sol in line 1077 there is even a conversion to uint8 >> byte(uint8(_nbytes));
    bytes32 queryId;                                    //Is it realy necessary to have it as state variable?
    struct Bet {                                        //Struct Variable for betting process
        address payable player;                         //msg.sender is the player
        uint value;                                     //betting value (double or loose)
        bool result;                                    //win or loose result
    }
    //* Events */
    event betTaken(address indexed player, bytes32 Id, uint value, bool result);
    event betPlaced(address indexed player,bytes32 queryId, uint value);
    event contractFunded(address contractOwner, uint funding);
    event LogNewProvableQuery(string description);
    event generatedRandomNumber(uint256 randomNumber);
    //* Mappings */
    mapping (bytes32 => Bet) public betting;            //Query Id coupling to Bet
    mapping (address => bool) public waiting;           //Msg.sender waiting system (Player have to wait until previous bet is taken and finished)
    //* Constructor */
    constructor() public {
        provable_setProof(proofType_Ledger);
        //flip();
    }
    //* Modifiers */
    modifier costs(uint cost){
        uint jackpot = address(this).balance / 2;
        require(msg.value <= jackpot, "Jackpot is the max bet you can make");   //This statement is not working yet
        require(msg.value >= cost, "The minimum bet you can make is 0.01 Ether");
        _;
    }
    //* Functions - Setter */
    //Oracle Callback Function of the flip() function
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            /*
             * @notice  The proof verification has failed! Handle this case
             *          however you see fit. --> Not sure what to do here.
            */
        }
        else {
        //Final result of random number creation (0-255 % 2 == 0 || 1)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
        //Condition decision: false == lose || true == win
        if(randomNumber == 0){
            betting[_queryId].result = false;
        }
        else if(randomNumber == 1){
            betting[_queryId].result = true;
            betting[_queryId].player.transfer((betting[_queryId].value)*2);
        }
        //Player address is not on waiting any more and can play again
        waiting[betting[_queryId].player] = false;
        //Emit event to Blockchain log (PlayerAddress, BetId, BetAmount, Result)
        emit generatedRandomNumber(randomNumber);
        emit betTaken(betting[_queryId].player, _queryId, betting[_queryId].value, betting[_queryId].result);
       }
    }
    //Placing a bet and simulate coin flip 
    function flip() public payable costs(0.01 ether){
        //Condition that player has no ongoing bet transaction
        require(waiting[msg.sender] == false);
        //Player address gets into waiting mode => Player is not able to place an other bet in this time
        waiting[msg.sender] = true;

        uint256 QUERY_EXECUTION_DELAY = 0;      //config: execution delay (0 for no delay)
        uint256 GAS_FOR_CALLBACK = 200000;      //config: gas fee for calling __callback function (200000 is standard)
        //Calling oracle to make random number request
        queryId = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);     //function to query a random number, it will call the __callback function
        //Initialize new Bet with player values and bind it to oracle queryId
        betting[queryId] = Bet({player: msg.sender, value: msg.value, result: false});
        //Emit Bet values as an event to Blockchain log 
        emit betPlaced(msg.sender, queryId, msg.value);
        //emit LogNewProvableQuery("Provable query was sent, standing by for answer...");
    }
    //Withdraw Funds - get Ether from contract
    function withdrawAll() public onlyContractOwner returns(uint){
        //Should require that no bet is prozess! Should wait and disalow all new bets!
        msg.sender.transfer(address(this).balance);
        assert(address(this).balance == 0);
        return address(this).balance;
    }
    //Fund the Contract - put Ether into contract
    function fundContract() public payable onlyContractOwner returns(uint){
        require(msg.value != 0);
        emit contractFunded(msg.sender, msg.value);
        return msg.value;
    }
    //* Functions - Getter */
    //Get balance of contract address
    function getContractBalance() public view returns (uint) {
        uint contractBalance = address(this).balance;
        return contractBalance;
    }

}