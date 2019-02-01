pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Player {
        string name;
        string status;
        address addr;
        bool hasAttacked;
        uint revealedId;
        uint itemId;
    }

    struct Item {
        uint num;
        string name;
    }

    uint private itemInitialValue = 1000;

    // Read/write Candidates
    mapping(uint => Player) public players;
    // Read/write items
    mapping(uint => Item) public items;

    // Store Candidates Count
    uint public playerCount;
    // Store item Count
    uint public itemCount;

    // Re-render page
    event StatusEvent ();
    // Error message display
    event ErrorEvent (string error);

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
    function registerPlayer () public {
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

        // show updated status
        emit StatusEvent();
    }

    // attack with given item
    function attack (uint _itemId) public {
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

        // require a valid item
        if (_itemId < 0 || _itemId >= itemCount){
            emit ErrorEvent('Error: Incorrect item chosen');
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
        }

        // trigger voted event
        emit StatusEvent();
    }

    // calculate who won
    function winner () private {

        // check revealed item match
        if (players[1].itemId != players[1].revealedId ){
            emit ErrorEvent('Player 2 won, Player 1 wrong item revealed');
            return;
        }

        if (players[2].itemId != players[2].revealedId ){
            emit ErrorEvent('Player 1 won, Player 2 wrong item revealed');
            return;
        }

        // calculate winner
        //Rock Case
        if (players[1].itemId == 0){
            if (players[2].itemId == 0) {
                emit ErrorEvent('Draw');
            } else if (players[2].itemId == 1) {
                emit ErrorEvent('Player 1 Won');
            } else {
                emit ErrorEvent('Player 2 Won');
            }
        }
        //Paper Case
        else if (players[1].itemId == 1){
            if (players[2].itemId == 0) {
                emit ErrorEvent('Player 1 Won');
            } else if (players[2].itemId == 1) {
                emit ErrorEvent('Draw');
            } else {
                emit ErrorEvent('Player 2 Won');
            }
        }
        //Scissor case
        else if (players[1].itemId == 2){
            if (players[2].itemId == 0) {
                emit ErrorEvent('Player 2 Won');
            } else if (players[2].itemId == 1) {
                emit ErrorEvent('Player 1 Won');
            } else {
                emit ErrorEvent('Draw');
            }
        }
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
