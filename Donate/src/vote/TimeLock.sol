// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "src/interface/ITimeLock.sol";
// import "src/uitls/SafeMath.sol";
import "src/vote/DAO.sol";

contract TimeLock is ITimeLock {

    // using SafeMath for uint;
    constructor(address _admin,uint _delay) {
        admin = _admin;
        delay = _delay;
    }

    address public admin;
    address public pendingAdmin;

    uint public delay;
    uint public constant GRACE_PERIOD = 10; 



    mapping (bytes32 => bool) public queuedTransactions;

    event NewDelay(uint indexed delay);
    event QueuedTransaction(
        address indexed target,
        bytes32 indexed txHash,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event CancelTransaction(
        address indexed target,
        bytes32 indexed txHash,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        address indexed target,
        bytes32 indexed txHash,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    modifier pendingAdminOnly {
        require(msg.sender == pendingAdmin,"TimeLock::pendingAdminOnly:You must be PendingAdmin.");
        _;
    }

    function setPendingAdmin(address _pendingAdmin) public {
        require(msg.sender == admin,"TimeLock::setPendingAdmin:You must be Admin.");
        pendingAdmin = _pendingAdmin;
    }

    function setDelay(uint _delay) public pendingAdminOnly{
        require(msg.sender == address(this),"TimeLock::setDelay:Call must come from TimeLock.");
        delay = _delay;
        emit NewDelay(delay);
    }



    function queuedTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external pendingAdminOnly returns (bytes32) {

        // require(eta >= getBlockNumber().add(delay),"TimeLock::queuedTransaction:It's too late.");
        require(eta >= getBlockNumber()+delay,"TimeLock::queuedTransaction:It's too late.");
        bytes32 txHash = keccak256(abi.encode(target,value,signature,data,eta));
        queuedTransactions[txHash] = true;
        emit QueuedTransaction(target, txHash, value, signature, data, eta);
        return txHash;

    }

    function cancelTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external pendingAdminOnly {

        bytes32 txHash = keccak256(abi.encode(target,value,signature,data,eta));
        queuedTransactions[txHash] = false;
        emit CancelTransaction(target, txHash, value, signature, data, eta);
        
    }

    function executeTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) public payable pendingAdminOnly returns (bytes memory) {

        bytes32 txHash = keccak256(abi.encode(target,value,signature,data,eta));

        require(queuedTransactions[txHash],"TimeLock::executeTransaction:Transaction hasn't been queued.");
        require(eta >= getBlockNumber(),"TimeLock::executeTransaction:Transaction hasn't started.");

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked( bytes4( keccak256( bytes( signature ) ) ),data);
        }
        
        (bool success,bytes memory returnData) = target.call{value:value}(callData);
        require(success,"TimeLock::executeTransaction:Transaction execution reverted.");

        emit ExecuteTransaction(target, txHash, value, signature, data, eta);

        return returnData;
    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }
}