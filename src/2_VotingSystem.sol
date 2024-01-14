// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VotingSystem {
    address public owner;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }

    mapping(address => Voter) public voters;
    Candidate[] public candidates;

    bool public electionEnded;

    event VoterRegistered(address indexed voter);
    event CandidateAdded(uint256 indexed id, string name);
    event ElectionResult(Candidate[] winner);

    //No event for Vote for Anonymous voting

    constructor() {
        owner = msg.sender;
    }

    function registerToVote() external {
        require(!voters[msg.sender].isRegistered, "You are already registered");
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender);
    }

    function addCandidate(string memory _name) external {
        require(msg.sender == owner, "Owner rights needed");
        require(!electionEnded, "Election ended");
        candidates.push(Candidate(_name, 0));
        emit CandidateAdded(candidates.length, _name);
    }

    function castVote(uint256 _candidateId) external {
        require(!electionEnded, "Election ended");
        require(_candidateId < candidates.length, "Invalid candidate ID");
        require(
            voters[msg.sender].isRegistered,
            "Only registered voters can perform this action"
        );
        require(!voters[msg.sender].hasVoted, "You have already voted");

        voters[msg.sender].hasVoted = true;
        candidates[_candidateId].voteCount++;
    }

    function getElectionResult() public view returns (Candidate[] memory) {
        require(candidates.length > 1, "Cannot end election with 1 candidate");

        uint maxVoteCount = 0;
        uint tieCount = 1;

        // Find the maximum vote count and count tied candidates
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > candidates[maxVoteCount].voteCount) {
                maxVoteCount = i;
                tieCount = 1; // Reset tie count
            } else if (
                candidates[i].voteCount == candidates[maxVoteCount].voteCount
            ) {
                tieCount++;
            }
        }

        // If there is a tie, return an array of tied candidates; otherwise, return the winner
        if (tieCount > 1) {
            Candidate[] memory tiedCandidates = new Candidate[](tieCount);
            uint index = 0;
            for (uint256 i = 0; i < candidates.length; i++) {
                if (
                    candidates[i].voteCount ==
                    candidates[maxVoteCount].voteCount
                ) {
                    tiedCandidates[index] = candidates[i];
                    index++;
                }
            }
            return tiedCandidates;
        } else {
            return new Candidate[](0); // Empty array to indicate a single winner
        }
    }

    function endElection() external {
        require(!electionEnded, "Election Already ended");
        require(msg.sender == owner, "Owner rights needed");
        electionEnded = true;
        emit ElectionResult(getElectionResult());
        //we getResults after voting ends
    }
}
