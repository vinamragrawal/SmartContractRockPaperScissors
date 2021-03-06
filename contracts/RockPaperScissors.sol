pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Player {
        string name;
        string status;
        address payable addr;
        bool hasAttacked;
        uint256 revealedId;
        uint256 itemId;
    }

    struct Item {
        uint num;
        string name;
    }

    uint private itemInitialValue = 0;

    // Read/write Candidates
    mapping(uint => Player) private players;
    // Read/write items
    mapping(uint => Item) private items;

    // Store Candidates Count
    uint private playerCount;
    // Store item Count
    uint private itemCount;

    //Random number generated based on member input
    uint256 private randomNumber = 1;

    //Timer for other player
    uint private timer = 0;
    uint private waitingForPlayer = 0;
    uint private waitTime = 2*60;

    // Re-render page
    event StatusEvent ();
    // Error message display
    event ErrorEvent (string error, address toAddr);
    // Announce Winner
    event WinnerEvent (string msg, string choice1, string choice2);
    // Start Timer
    event StartTimerEvent (address addr, uint waitTime);

    //Add new player
    function addPlayer (string memory _name) private {
        playerCount ++;
        players[playerCount] = Player(_name, "Waiting to register", address(0), false, itemInitialValue, itemInitialValue);
    }

    //Add new item
    function addItem (string memory _name) private {
        items[itemCount] = Item(itemCount, _name);
        itemCount ++;
    }

    //register players
    function registerPlayer (uint randNum) payable public {
        if (msg.sender == players[1].addr || msg.sender == players[2].addr) {
            emit ErrorEvent('Error: User Already registered', msg.sender);
            return;
        }

        //Require that registration fees is sent
        require( msg.value >= 1 ether, "Not enough fees sent");

        if (players[1].addr == address(0)) {
            players[1].addr = msg.sender;
            players[1].status = "Registered";
        } else if (players[2].addr == address(0)) {
            players[2].addr = msg.sender;
            players[2].status = "Waiting to choose";
            players[1].status = "Waiting to choose";
        } else {
            emit ErrorEvent('Error: No more space for new users', msg.sender);
            return;
        }

        //Update random with user input
        randomNumber = uint8(uint256(keccak256(abi.encodePacked(randNum + randomNumber)))%251);

        // show updated status
        emit StatusEvent();
    }

    // attack with given item
    function attack (uint256 _itemId) public {
        uint playerId = 0;

        // Check if player registered
        if (players[1].addr == msg.sender){
            playerId = 1;
        } else if (players[2].addr == msg.sender){
            playerId = 2;
        } else {
            emit ErrorEvent('Error: Only registered Players can attack', msg.sender);
            return;
        }

        //Check if both players registered
        if (players[1].addr == address(0) || players[2].addr == address(0)){
            emit ErrorEvent('Error: Wait for other player to register', msg.sender);
            return;
        }

        // require to check if already not chosen
        if (players[playerId].hasAttacked){
            emit ErrorEvent('Error: Already chosen an item', msg.sender);
            return;
        }

        // mark as item selected
        players[playerId].itemId = _itemId;
        players[playerId].hasAttacked = true;

        players[playerId].status = "Chosen item";

        // trigger voted event
        emit StatusEvent();
    }

    // reveal chosen item
    function revealItem (uint _itemId) public {
        uint playerId = 0;

        //Choose a player from Registered
        if (players[1].addr == msg.sender){
            playerId = 1;
        } else if (players[2].addr == msg.sender){
            playerId = 2;
        } else {
            emit ErrorEvent('Error: Only registered Players can attack', msg.sender);
            return;
        }

        //Check if both players chosen
        if (players[1].itemId == itemInitialValue || players[2].itemId == itemInitialValue){
            emit ErrorEvent('Error: Wait for other player to vote', msg.sender);
            return;
        }

        //Check item equal to original
        players[playerId].revealedId = _itemId;
        players[playerId].status = "Revealed item";

        uint otherPlayer = 3 - playerId;

        if (players[otherPlayer].revealedId != itemInitialValue) {
            getWinner();
            return;
        } else {
            //start timer for other player
            timer = now;
            waitingForPlayer = otherPlayer;
            emit StartTimerEvent(players[otherPlayer].addr, waitTime);
        }

        // trigger voted event
        emit StatusEvent();
    }

    // calculate who won
    function getWinner () private {

        // check revealed item match
        if (players[1].itemId != uint256(keccak256(abi.encodePacked(players[1].revealedId + randomNumber)))){
            emit WinnerEvent('Player 2 won, Player 1 wrong item revealed', '', '');
            sendFundsToPlayer(2);
            resetGame();
            return;
        }

        if (players[2].itemId != uint256(keccak256(abi.encodePacked(players[2].revealedId + randomNumber)))){
            emit WinnerEvent('Player 1 won, Player 2 wrong item revealed', '', '');
            sendFundsToPlayer(1);
            resetGame();
            return;
        }

        uint player1Item =  players[1].revealedId % itemCount;
        uint player2Item =  players[2].revealedId % itemCount;

        // calculate winner
        //Rock Case
        if (player1Item == 0){
            if (player2Item == 0) {
                emit WinnerEvent('Draw', "Rock", "Rock");
                sendFundsToPlayer(0);
            } else if (player2Item == 1) {
                emit WinnerEvent('Player 1 Won', "Rock", "Paper");
                sendFundsToPlayer(1);
            } else {
                emit WinnerEvent('Player 2 Won', "Rock", "Scissors");
                sendFundsToPlayer(2);
            }
        }
        //Paper Case
        else if (player1Item == 1){
            if (player2Item == 0) {
                emit WinnerEvent('Player 1 Won', "Paper", "Rock");
                sendFundsToPlayer(1);
            } else if (player2Item == 1) {
                emit WinnerEvent('Draw', "Paper", "Paper");
                sendFundsToPlayer(0);
            } else {
                emit WinnerEvent('Player 2 Won', "Paper", "Scissors");
                sendFundsToPlayer(2);
            }
        }
        //Scissor case
        else if (player1Item == 2){
            if (player2Item == 0) {
                emit WinnerEvent('Player 2 Won', "Scissors", "Rock");
                sendFundsToPlayer(2);
            } else if (player2Item == 1) {
                emit WinnerEvent('Player 1 Won', "Scissors", "Paper");
                sendFundsToPlayer(1);
            } else {
                emit WinnerEvent('Draw', "Scissors", "Scissors");
                sendFundsToPlayer(0);
            }
        }

        resetGame();
    }

    function sendFundsToPlayer(uint playerId) private {
        //Used transfer instead of call.value for security reasons
        if (playerId == 0) {
            // Split the reward in case its a tie.
            players[1].addr.transfer(getBalance() / 2);
            players[2].addr.transfer(getBalance());
        } else {
            //Send to funds to given player
            players[playerId].addr.transfer(getBalance());
        }
    }

    function timeUp () public {
        if (now - timer >= waitTime){
            if (waitingForPlayer == 1){
                emit WinnerEvent('Player 2 won, Time up for player 1', '', '');
                resetGame();
            } else if (waitingForPlayer == 2){
                emit WinnerEvent('Player 1 won, Time up for player 2', '', '');
                resetGame();
            }
        }
    }

    function getPlayerCount () public view returns (uint) {
        return playerCount;
    }

    function getContractRandomNumber () public view returns (uint256) {
        return randomNumber;
    }

    function getPlayer (uint id) public view
        returns (string memory name, string memory status, address addr,
                 bool hasAttacked, uint256 revealedId, uint256 itemId) {
        Player memory p =  players[id];
        return (p.name, p.status, p.addr, p.hasAttacked, p.revealedId, p.itemId);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function resetGame () private {
        // Reset contract for next round
        delete players[1];
        delete players[2];
        playerCount = 0;
        randomNumber = 0;
        timer = 0;
        waitingForPlayer = 0;
        addPlayer("Player 1");
        addPlayer("Player 2");
    }

    // Constructor
    constructor() public {
        addPlayer("Player 1");
        addPlayer("Player 2");
        addItem("Rock");
        addItem("Paper");
        addItem("Scissor");
    }
}
