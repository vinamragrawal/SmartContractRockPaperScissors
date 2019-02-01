pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Read/write Candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    event votedEvent (
        uint indexed _candidateId
    );

    // Store accounts that have voted
    mapping(address => bool) public voters;

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }

    struct Player {
        string name;
        string status;
        address addr;
    }

    // Read/write Candidates
    mapping(uint => Player) public players;

    // Store Candidates Count
    uint public playerCount;

    // Re-render page
    event StatusEvent ();

    // Error message display
    event ErrorEvent (string error);

    //Add new player
    function addPlayer (string memory _name) private {
      playerCount ++;
      players[playerCount] = Player(_name, "Waiting to register", address(0));
    }

    //register players
    function registerPlayer () public {
        if (msg.sender == players[1].addr || msg.sender == players[2].addr) {
            emit ErrorEvent('Error: User Already registered');
            return;
        }

        //TODO: fix this move to else branch
        require(players[1].addr == address(0) || players[2].addr == address(0));

        uint playerId = 0;

        if (players[1].addr == address(0)) {
            playerId = 1;
        } else if (players[2].addr == address(0)) {
            playerId = 2;
        }
        players[playerId].addr = msg.sender;
        players[playerId].status = "Registered";

        // trigger voted event
        emit StatusEvent();
    }

    // Constructor
    constructor() public {
      addCandidate("Player 1");
      addCandidate("Player 2");
      addPlayer("Player 1");
      addPlayer("Player 2");
    }
}
