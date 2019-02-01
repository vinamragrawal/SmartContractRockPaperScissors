pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Player {
        string name;
        string status;
        address addr;
        bool hasAttacked;
        uint itemNo;
    }

    struct Item {
        uint num;
        string name;
    }

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
      players[playerCount] = Player(_name, "Waiting to register", address(0), false, 0);
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
            players[2].status = "Waiting to vote";
            players[1].status = "Waiting to vote";
        } else {
          emit ErrorEvent('Error: No more space for new users');
          return;
        }

        // trigger voted event
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
        players[playerId].itemNo = _itemId;
        players[playerId].hasAttacked = true;

        players[playerId].status = "Chosen item";

        // trigger voted event
        emit StatusEvent();
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
