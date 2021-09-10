//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapContract is Ownable {
    using SafeMath for uint256;
    address payable public tokenOwner;
    address public tokenAddress;
    uint256 public rateTokenOwner;
    uint256 public rateTokenAddress;

    bool public reset = true;

    struct TransferRequest {
        address toAddress;
        address txAddress;
        uint256 amount;
        bool completed;
        uint256 index;
    }

    uint256 private constant decimalFactor = 10**uint256(18);
    uint256 _numRequests;
    mapping(uint256 => TransferRequest) _requests;

    event RequestToTransfer(
        uint256 numRequests,
        uint256 requestId,
        address investor,
        uint256 amount
    );
    event TransferExecuted(
        uint256 idx,
        address indexed investor,
        uint256 amount
    );

    /**
     * @dev only the token owner and owner of the contract
     *  can execute with this modifier
     */
    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner || msg.sender == owner());
        _;
    }

    /**
     * @dev constructor
     * @param _tokenAddress address of the swap controller contract
     * @param _tokenOwner address of the owner of the token
     */
    constructor(address  _tokenAddress, address payable _tokenOwner, uint _rateTokenOwner, uint _rateTokenAddress)
        public
        Ownable()
    {
        require(_tokenAddress != address(0));
        require(_tokenOwner != address(0));

        tokenAddress = _tokenAddress;
        tokenOwner = _tokenOwner;
        rateTokenOwner = _rateTokenOwner;
        rateTokenAddress = _rateTokenAddress;
    }

    /**
     * @dev main function for creating transfer requests
     * @param _toAddress address destination to send SHOPIN tokens
     * @param _txAddress address address of SHOP transaction
     * @param _amount uint amount of tokens requested in swap
     * @return bool success boolean
     */
    function requestTransfer(
        address _toAddress,
        address _txAddress,
        uint256 _amount
    ) public returns (bool) {
        // request cannot already exist for this transaction
        require(!requestTransferExists(_txAddress));
        // cannot request transfer of 0 SHOP tokens
        require(_amount > 0);
        // ensure no zero address
        require(_txAddress != address(0));

        uint256 _requestId = _numRequests++;
        TransferRequest memory req = TransferRequest(
            _toAddress,
            _txAddress,
            _amount,
            false,
            _requestId
        );
        _requests[_requestId] = req;
        // emit
        emit RequestToTransfer(_numRequests, _requestId, _txAddress, _amount);
        return true;
    }

    /**
     * @dev is address in list of transfer requests?
     * @param _txAddress addr address we're checking
     * @return bool if the address has already submitted a transfer request
     */
    function requestTransferExists(address _txAddress)
        public
        view
        returns (bool)
    {
        if (_numRequests == 0) {
            return false;
        }

        for (uint256 i = 0; i < _numRequests; i++) {
            TransferRequest memory req = _requests[i];
            if (req.txAddress == _txAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev execute transfers for all unexecuted ones that can be swapped
     * @return boolean if the entire operation completed successfully or not
     */
    function executeTransfers() public onlyTokenOwner returns (bool) {
        if (_numRequests == 0) return false;
        uint256 numRequests = _numRequests;
        ERC20 token = ERC20(tokenAddress);
        for (uint256 i = 0; i < numRequests; i++) {
            TransferRequest storage req = _requests[i];
            if (!req.completed) {
                // Execute transfer
                token.transfer(req.toAddress, req.amount);
                emit TransferExecuted(i, req.toAddress, req.amount);
                _requests[i].completed = true;
            }
        }
        return true;
    }

    function withdrawAllTokens() external onlyTokenOwner returns (bool) {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    function withdrawAllEth() public onlyTokenOwner returns (bool) {
        tokenOwner.transfer(address(this).balance);
    }

    /**
     * @dev get the token owner address
     * @return address of the token owner
     */
    function getTokenOwnerAddress() public view returns (address) {
        return tokenOwner;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev get transfer request amount for a transfer request
     * @param idx index of the transfer request in the list
     * @return uint the amount requested in the transfer
     */
    function getTransferRequestAmount(uint256 idx)
        public
        view
        onlyTokenOwner
        returns (uint256)
    {
        return _requests[idx].amount;
    }

    /**
     * @dev get the transfer request investor address
     * @param idx the index of the transfer request in the list
     * @return address the address of the investor
     */
    function getTransferRequestInvestor(uint256 idx)
        public
        view
        onlyTokenOwner
        returns (address)
    {
        return _requests[idx].toAddress;
    }

    /**
     * @dev get the completed status of the transfer request
     * @param idx the index of the transfer request
     * @return bool the status of the completed transfer request
     */
    function getTransferRequestCompleted(uint256 idx)
        public
        view
        onlyTokenOwner
        returns (bool)
    {
        return _requests[idx].completed;
    }

    /**
     * @dev get the txaddress
     * @param idx the index of the transfer request
     * @return tx address
     */
    function getTransferRequestTxHash(uint256 idx)
        public
        view
        onlyTokenOwner
        returns (address)
    {
        return _requests[idx].txAddress;
    }

    /**
     * @dev get the number of all transfer requests
     * @return uint the amount of transfer requests
     */
    function getTransferRequestCount()
        public
        view
        onlyTokenOwner
        returns (uint256)
    {
        return _numRequests;
    }
}
