// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {GovernorEvent,GovernorImpV2} from "src/uitls/GovernTool.sol";
import "src/vote/DAO.sol";
import "src/interface/ITimeLock.sol";
import "src/vote/Token.sol";
import "src/interface/IToken.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract GovernImp is GovernorEvent,GovernorImpV2 {
     
    address public token;
    address public dao;

    uint public minVotes = 100;
    
    function initialize(
        address _token,
        address _dao,
        address _timeLock,
        uint _votingDelay,
        uint _votingPeriod
        ) public {

            require(address(timeLock) == address(0),"GovernImp::initialize:Can only initilize once.");
            require(_timeLock != address(0),"GovernImp::initialize:Invalid TimeLock Address.");
            require(_token != address(0),"GovernImp::initialize:Invalid Token Address.");
            require(_dao != address(0),"GovernImp::initialize:Invalid DAO Address.");

            token = _token;
            dao = _dao;
            timeLock = ITimeLock(_timeLock);
            votingDelay = _votingDelay;
            votingPeriod = _votingPeriod;
    }

    function state(uint _proposalId) public view returns(ProposalState) {
        
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.canceled) {
            return(ProposalState.Canceled);
        } else if (block.number <= proposal.startblock) {
            return(ProposalState.Penging);
        } else if (block.number <= proposal.endblock) {
            return(ProposalState.Active);
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < minVotes) {
            return(ProposalState.Defeaded);
        } else if (proposal.eta == 0) {
            return(ProposalState.Succeed);
        } else if (proposal.executed) {
            return(ProposalState.Executed);
        } else if (block.number >= proposal.eta + timeLock.GRACE_PERIOD()) {
            return(ProposalState.Expired);
        } else {
            return(ProposalState.Queued);
        }
    }

    function propose(
        address[] memory target,
        string[] memory signatures,
        bytes[] memory calldatas,
        uint[] memory values,
        string memory description
        ) public payable returns (uint proposalId) {

        return _proposeInternal(msg.sender, target, signatures, calldatas, values, description);
        
    }

    function _proposeInternal(
        address proposer,
        address[] memory target,
        string[] memory signatures,
        bytes[] memory calldatas,
        uint[] memory values,
        string memory description
        ) internal returns (uint proposalId) {

        uint latestProposalId = latestProposalIds[proposer];

        if (latestProposalId != 0) {
            ProposalState laststProposalState = state(latestProposalId);
            require(laststProposalState != ProposalState.Active,"GovernImp::_proposeInternal:Lastst Proposal is Active.");
            require(laststProposalState != ProposalState.Penging,"GovernImp::_proposeInternal:Lastst Proposal is Penging.");
        }

        uint startBlock = block.number + votingDelay;
        uint endBlock = startBlock + votingPeriod;

        proposalCount++;
        uint newProposalId = proposalCount;
        Proposal storage newProposal = proposals[newProposalId];

        newProposal.id = newProposalId;
        newProposal.proposer = proposer;
        newProposal.targets = target;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.forVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;
        newProposal.startblock = startBlock;
        newProposal.endblock = endBlock;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            newProposal.proposer,
            newProposal.targets,
            newProposal.values,
            newProposal.signatures,
            newProposal.calldatas,
            newProposal.startblock,
            newProposal.endblock,
            description);

        return newProposal.id;
    }

    //support: 0:for ; 1:against ; 2:abstain.
    function castVote(uint proposalId,uint8 support) external {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            _castVoteInternal(msg.sender,proposalId,support),
            ""
            );
    }

    function _castVoteInternal(address voter,uint proposalId,uint8 support) internal returns (uint256) {
        
        require(state(proposalId) == ProposalState.Active,"GovernImp::_castVoteInternal:Voting is Closed.");
        require(support <= 2,"GovernImp::_castVoteInternal:Support Worng.");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        uint256 votes = Token(token).getPriorVotes(voter, proposal.startblock);

        if (support == 0) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 1) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;

    }

    function queue(uint proposalId) external {

        require(state(proposalId) == ProposalState.Succeed,"GovernImp::queue:The Proposal is not Succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = block.number + timeLock.delay();
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);

    }

    function _queueOrRevertInternal(address target,uint value,string memory signature,bytes memory data,uint eta) internal {

        require(!timeLock.queuedTransactions(keccak256(abi.encode(target,value,signature,data,eta))),"GovernorBravo::queueOrRevertInternal:Proposal action already queued at eta.");
        timeLock.queuedTransaction(target, value, signature, data, eta);

    }

    function execute(uint proposalId) external payable {
        
        require(state(proposalId) == ProposalState.Queued,"GovernorBravo::execute:Proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timeLock.executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        
        emit ProposalExecuted(proposalId);
    }
}