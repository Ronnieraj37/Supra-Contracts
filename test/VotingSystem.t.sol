// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../src/2_VotingSystem.sol";

interface CheatCodes {
    function addr(uint256) external returns (address);
}

contract VotingSystemTest is Test {
    VotingSystem public votingSystem;
    address public owner;
    address public voter1;
    address public voter2;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        owner = msg.sender;
        voter1 = cheats.addr(1);
        voter2 = cheats.addr(2);

        votingSystem = new VotingSystem();
    }

    function testDoubleRegistration() public {
        votingSystem.registerToVote();
        vm.expectRevert(bytes("You are already registered"));
        votingSystem.registerToVote();
    }

    function testNonOwnerAddCandidate() public {
        vm.prank(voter1);
        vm.expectRevert(bytes("Owner rights needed"));
        votingSystem.addCandidate("Candidate 1");
    }

    function endElectionWithoutCandidates() public {
        votingSystem.addCandidate("Candidate 1");
        votingSystem.endElection();
        vm.expectRevert(bytes("Cannot end election with 1 candidate"));
    }

    function testAddCandidateAfterElectionEnded() public {
        votingSystem.addCandidate("Candidate 1");
        votingSystem.addCandidate("Candidate 2");
        votingSystem.endElection();
        vm.expectRevert(bytes("Election ended"));
        votingSystem.addCandidate("Candidate 3");
    }

    function testInvalidCandidateVote() public {
        vm.expectRevert(bytes("Invalid candidate ID"));
        votingSystem.castVote(1);
    }

    function testDoubleVote() public {
        votingSystem.registerToVote();
        votingSystem.addCandidate("Candidate 1");
        votingSystem.castVote(0);
        vm.expectRevert(bytes("You have already voted"));
        votingSystem.castVote(0);
    }

    function testElectionResultWithoutCandidates() public {
        vm.expectRevert(bytes("Cannot end election with 1 candidate"));
        votingSystem.getElectionResult();
    }

    function testEndElectionNonOwner() public {
        vm.prank(voter1);
        vm.expectRevert(bytes("Owner rights needed"));
        votingSystem.endElection();
    }

    function testEndElectionTwice() public {
        votingSystem.addCandidate("Candidate 1");
        votingSystem.addCandidate("Candidate 2");
        votingSystem.endElection();
        vm.expectRevert(bytes("Election Already ended"));
        votingSystem.endElection();
    }

    function testElectionResultWithMultipleWinners() public {
        votingSystem.registerToVote();
        votingSystem.addCandidate("Candidate 1");
        votingSystem.addCandidate("Candidate 2");

        vm.prank(voter1);
        votingSystem.registerToVote();
        vm.prank(voter1);
        votingSystem.castVote(0);

        vm.prank(owner);
        votingSystem.registerToVote();
        votingSystem.castVote(1);

        votingSystem.endElection();
        VotingSystem.Candidate[] memory result = votingSystem
            .getElectionResult();

        assertTrue(
            result.length == 2,
            "There should be two winners in the election result"
        );
    }

    function testVoteAfterElectionEndedWithEvents() public {
        votingSystem.registerToVote();
        votingSystem.addCandidate("Candidate 1");
        votingSystem.addCandidate("Candidate 2");
        votingSystem.endElection();

        vm.expectRevert("Election ended");
        votingSystem.castVote(0);
    }

    function testVoteForInvalidCandidate() public {
        votingSystem.registerToVote();
        votingSystem.addCandidate("Candidate 1");

        vm.expectRevert("Invalid candidate ID");
        votingSystem.castVote(1);
    }

    function testVoteWithoutRegistration() public {
        votingSystem.addCandidate("Candidate 1");
        vm.expectRevert("Only registered voters can perform this action");
        votingSystem.castVote(0);
    }
}
