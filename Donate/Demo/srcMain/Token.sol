// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "src/interface/IToken.sol";
import "src/uitls/SafeMath.sol";


contract Token is ERC20, Itoken {
    using SafeMath for uint256;

    struct Checkpoint {
        uint256 blocknumber;
        uint256 Votes;
    }

    address public owner;
    address public dao;

    mapping(address => address) public VoteTarget;

    mapping(address => mapping(uint256 => Checkpoint)) public Checkpoints;

    mapping(address => uint256) public numCheckpoints;

    event VoteTargetChanged(
        address indexed NewVoteTarge,
        address indexed OldVoteTarge,
        address indexed Voter
    );

    event VotesChanged(
        address indexed VoteTarge,
        uint256 NewVotes,
        uint256 OldVotes
    );

    constructor() ERC20("VoteCion", "VC") {
        owner = msg.sender;
    }

    modifier OwnerOnly() {
        require(msg.sender == owner, "Token::OwnerOnly:You are not Owner.");
        _;
    }
    modifier DAOOnly() {
        require(msg.sender == dao, "Token::DAOOnly:You are not DAO");
        _;
    }

    function setDAO(address _dao) external OwnerOnly {
        dao == _dao;
    }

    function mint(address account, uint256 amount) external DAOOnly {
        _mint(account, amount);
    }

    function _writeCheckpoint(
        address _owner,
        uint256 _votes,
        uint256 _oldVotes,
        uint256 nCheckpoints
    ) internal {
        uint256 blocknumber = block.number;
        // uint256 nCheckpoints = numCheckpoints[_owner];
        // uint256 _oldVotes = Checkpoints[_owner][nCheckpoints - 1].Votes;

        if (
            nCheckpoints > 0 &&
            Checkpoints[_owner][nCheckpoints - 1].blocknumber == blocknumber
        ) {
            Checkpoints[_owner][nCheckpoints - 1].Votes = _votes;
        } else {
            Checkpoints[_owner][nCheckpoints] = Checkpoint(blocknumber, _votes);
            numCheckpoints[_owner] = nCheckpoints + 1;
        }

        emit VotesChanged(_owner, _votes, _oldVotes);
    }

    function _moveTargetVotes(
        address _oldTarget,
        uint _votes,
        address _newTarget
    ) internal {
        if (_oldTarget != _newTarget && _votes > 0) {
            if (_oldTarget != address(0)) {
                uint256 nCheckpoints = numCheckpoints[_oldTarget];
                uint256 _oldOldVotes = nCheckpoints > 0
                    ? Checkpoints[_oldTarget][nCheckpoints - 1].Votes
                    : 0;
                uint256 _newOldVotes = _oldOldVotes.sub(_votes);
                _writeCheckpoint(
                    _oldTarget,
                    _newOldVotes,
                    _oldOldVotes,
                    nCheckpoints
                );
            }

            if (_newTarget != address(0)) {
                uint256 nCheckpoints = numCheckpoints[_newTarget];
                uint256 _oldNewVotes = nCheckpoints > 0
                    ? Checkpoints[_newTarget][nCheckpoints - 1].Votes
                    : 0;
                uint256 _newNewVotes = _oldNewVotes.sub(_votes);
                _writeCheckpoint(
                    _newTarget,
                    _newNewVotes,
                    _oldNewVotes,
                    nCheckpoints
                );
            }
        }
    }

    function moveTarget(address _target) external {
        // require(_target != address(0),"ADDRESS(0)");
        _moveTarget(msg.sender, _target);
    }

    function _moveTarget(address _voter, address _target) internal {
        address _oldTarget = VoteTarget[_voter];
        VoteTarget[_voter] = _target;
        uint256 _votes = balanceOf(_voter);
        _moveTargetVotes(_oldTarget, _votes, _target);
    }

    function getPriorVotes(address Voter,uint blocknumber) external view override returns (uint) {
        require(blocknumber > block.number , "The Target hasn't start.");


        uint256 nCheckpoints = numCheckpoints[Voter];
        

        if (nCheckpoints == 0 || Checkpoints[Voter][0].blocknumber > blocknumber) {
            return 0;
        }


        if (Checkpoints[Voter][nCheckpoints - 1].blocknumber == blocknumber) {
            return Checkpoints[Voter][nCheckpoints - 1].Votes;
        }


        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = Checkpoints[Voter][center];
            if (cp.blocknumber == blocknumber) {
                return cp.Votes;
            } else if (cp.blocknumber < blocknumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return Checkpoints[Voter][lower].Votes;
    }
}