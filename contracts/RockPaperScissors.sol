pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Player {
        string name;
        string status;
        address addr;
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
    mapping(uint => Player) public players;
    // Read/write items
    mapping(uint => Item) public items;

    // Store Candidates Count
    uint public playerCount;
    // Store item Count
    uint public itemCount;

    //Random number generated based on member input
    uint256 public randomNumber = 1;

    //Timer for other player
    uint public timer = 0;
    uint private waitingForPlayer = 0;
    // uint private waitTime = 2*60;
    uint private waitTime = 10;

    // Re-render page
    event StatusEvent ();
    // Error message display
    event ErrorEvent (string error);
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
    function registerPlayer (uint randNum) public {
        if (msg.sender == players[1].addr || msg.sender == players[2].addr) {
            emit ErrorEvent('Error: User Already registered');
            return;
        }
        if (players[1].addr == address(0)) {
            players[1].addr = msg.sender;
            players[1].status = "Registered";
        } else if (players[2].addr == address(0)) {
            players[2].addr = msg.sender;
            players[2].status = "Waiting to choose";
            players[1].status = "Waiting to choose";
        } else {
            emit ErrorEvent('Error: No more space for new users');
            return;
        }

        //Update random with user input
        randomNumber = randNum ^ randomNumber;

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
            emit ErrorEvent('Error: Only registered Players can attack');
            return;
        }

        //Check if both players registered
        if (players[1].addr == address(0) || players[2].addr == address(0)){
            emit ErrorEvent('Error: Wait for other player to register');
            return;
        }

        // require to check if already not chosen
        if (players[playerId].hasAttacked){
            emit ErrorEvent('Error: Already chosen an item');
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
            emit ErrorEvent('Error: Only registered Players can attack');
            return;
        }

        //Check if both players chosen
        if (players[1].itemId == itemInitialValue || players[2].itemId == itemInitialValue){
            emit ErrorEvent('Error: Wait for other player to vote');
            return;
        }

        //Check item equal to original
        players[playerId].revealedId = _itemId;
        players[playerId].status = "Revealed item";

        uint otherPlayer = 3 - playerId;

        if (players[otherPlayer].revealedId != itemInitialValue) {
            winner();
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
    function winner () private {

        // check revealed item match
        if (players[1].itemId != uint256(keccak256(abi.encodePacked(players[1].revealedId + randomNumber)))){
            emit WinnerEvent('Player 2 won, Player 1 wrong item revealed', '', '');
            resetGame();
            return;
        }

        if (players[2].itemId != uint256(keccak256(abi.encodePacked(players[2].revealedId + randomNumber)))){
            emit WinnerEvent('Player 1 won, Player 2 wrong item revealed', '', '');
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
            } else if (player2Item == 1) {
                emit WinnerEvent('Player 1 Won', "Rock", "Paper");
            } else {
                emit WinnerEvent('Player 2 Won', "Rock", "Scissors");
            }
        }
        //Paper Case
        else if (player1Item == 1){
            if (player2Item == 0) {
                emit WinnerEvent('Player 1 Won', "Paper", "Rock");
            } else if (player2Item == 1) {
                emit WinnerEvent('Draw', "Paper", "Paper");
            } else {
                emit WinnerEvent('Player 2 Won', "Paper", "Scissors");
            }
        }
        //Scissor case
        else if (player1Item == 2){
            if (player2Item == 0) {
                emit WinnerEvent('Player 2 Won', "Scissors", "Rock");
            } else if (player2Item == 1) {
                emit WinnerEvent('Player 1 Won', "Scissors", "Paper");
            } else {
                emit WinnerEvent('Draw', "Scissors", "Scissors");
            }
        }

        resetGame();
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
