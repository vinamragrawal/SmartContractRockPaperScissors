pragma solidity ^0.5.0;

contract RockPaperScissors {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Read/write Candidates
    mapping(uint => Candidate) public candidates;

    string public candidate;

    // Store Candidates Count
    uint public candidatesCount;

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // Constructor
    constructor() public {
       candidate = "Candidate 1";

      addCandidate("Candidate 1");
      addCandidate("Candidate 2");
    }
}
