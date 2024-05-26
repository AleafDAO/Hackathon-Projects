
pragma solidity ^0.8.13;

import "src/interface/ITimeLock.sol";

contract GovernorEvent {
    
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    event ProposalCanceled(uint id);

    event ProposalQueued(uint id, uint eta);

    event ProposalExecuted(uint id);

    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );

    event VoteCast(
        address indexed voter,
        uint proposalId,
        uint8 support,
        uint votes,
        string reason
    );
    
}

contract GovernorImpV1 {

    address public admin;

    address public pendingadmin;

    address public implementation;

}

contract GovernorImpV2 {

    ITimeLock public timeLock;
    
    uint public votingDelay;

    uint public votingPeriod;

    mapping (address => uint) public latestProposalIds;

    mapping (uint => Proposal) proposals;

    uint public proposalCount;

    struct Proposal {

        uint id;
        address proposer;
        uint eta;
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        uint[] values;
        uint startblock;
        uint endblock;
        uint forVotes;
        uint againstVotes;
        uint abstainVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;

    }
    

    struct Receipt {

        bool hasVoted;
        uint8 support;
        uint256 votes;

    }

    enum ProposalState {

        Penging,
        Active,
        Canceled,
        Defeaded,
        Succeed,
        Queued,
        Expired,
        Executed

    }
    
}