//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "./SwapContract.sol";

contract SwapFactory is Ownable {

  address payable public tokenOwner; // Owner token
  address public tokenAddress; //  token which sender wanna exchange

  // index of created contracts
  struct SwapContractStruct {
    address contractAddress; 
    uint index;
    bytes32 name; // i.e : TRUSTK/USDT 
  }

  mapping (uint => SwapContractStruct) private contractStructs;
  uint[] private contractIndex;

  event ContractCreated(uint index, bytes32 name);
  event ContractRemoved(uint index);
  event ContractUpdated(uint index, bytes32 name);

  /**
   * @dev constructor
   */
  constructor(
    address payable _tokenOwner,
    address _tokenAddress
  )
    Ownable()
    public
  {
    require(_tokenAddress != address(0));
    require(_tokenOwner != address(0));

    tokenAddress = _tokenAddress;
    tokenOwner = _tokenOwner;
  }

  // Contract creation functions

  /**
   * @dev check if a contract is actually a contract set in the contract
   * @param _contractIndex the index of the contractStructs list
   * @return bool is a contract or not
   */
  function isContract(uint _contractIndex)
    public
    view 
    returns (bool)
  {
    if (contractIndex.length == 0) return false;
    return contractStructs[_contractIndex].index == _contractIndex;
  }

  /**
   * @dev add a contract to the list
   *  and deploy the new contract on the blockchain
   * @param name bytes32 of the name of the contract
   * @return index uint of the index in the list of the contract
   */
  function insertContract(
    bytes32 name,
    uint _rateTokenOwner, 
    uint _rateTokenAddress
  )
    public
    returns (uint index)
  {
    require(!contractByNameExists(name));
    uint _contractIndex = getContractCount();
    require(!isContract(_contractIndex));

    SwapContract c = new SwapContract(
      tokenAddress,
      tokenOwner,
      _rateTokenOwner,
      _rateTokenAddress
    );
    c.transferOwnership(msg.sender);
    contractStructs[_contractIndex].name = name;
    contractIndex.push(_contractIndex);
    contractStructs[_contractIndex].index = contractIndex.length - 1;
    contractStructs[_contractIndex].contractAddress = address(c);

    emit ContractCreated(contractStructs[_contractIndex].index, contractStructs[_contractIndex].name);
    return contractStructs[_contractIndex].index;
  }

  /**
   * @dev delete a contract from the list
   * @param _contractIndex the uint index in the contract list
   * @return index uint of the index deleted
   */
  function removeContract(
    uint _contractIndex
  )
    onlyOwner
    public
    returns (uint index)
  {
    require(isContract(_contractIndex));
    delete contractStructs[_contractIndex];
    emit ContractRemoved(_contractIndex);
    return _contractIndex;
  }

  /**
   * @dev get a contract in the contract list
   * @param _contractIndex uint of the contract instance
   * @return (bytes32, address, uint) details of the contract
   */
  function getContract(
    uint _contractIndex
  )
    public
    view
    returns (bytes32, address, uint)
  {
    require(isContract(_contractIndex));
    return (
      contractStructs[_contractIndex].name,
      contractStructs[_contractIndex].contractAddress,
      contractStructs[_contractIndex].index
    );
  }

  /**
   * @dev update the name of the contract in the contract list
   * @param _contractIndex uint index of the contract in the list
   * @param newName bytes32 of the new name of the contract
   */
  function updateContractName(
    uint _contractIndex,
    bytes32 newName
  )
    public
    returns (bool success)
  {
    require(isContract(_contractIndex));
    require(!contractByNameExists(newName));

    contractStructs[_contractIndex].name = newName;
    emit ContractUpdated(_contractIndex, contractStructs[_contractIndex].name);
    return true;
  }

  /**
   * @dev get the total count of contracts in the contract
   * @return contractCount uint of the number of contracts
   */
  function getContractCount()
    public
    view
    returns (uint contractCount)
  {
    return  contractIndex.length;
  }

  /**
   * @dev does a contract by its name already exist in the contract
   * @param name bytes32 of the name to check
   * @return bool if the contract exists in the contract
   */
  function contractByNameExists(
    bytes32 name
  )
    public
    view
    returns (bool)
  {
    if (contractIndex.length == 0) return false;
    for (uint i = 0; i < contractIndex.length; i++) {
      if (stringToUint(contractStructs[i].name) == stringToUint(name)) {
        return true;
      }
    }
    return false;
  }

 
  function contractIndexForName(bytes32 name)
    public
    view
    returns (bool found, uint index)
  {
    if(contractIndex.length == 0) return (false, 0);
    for (uint i = 0; i < contractIndex.length; i++) {
      if (stringToUint(contractStructs[i].name) == stringToUint(name)) {
        return (true, i);
      }
    }
    return (false, 0);
  }

  /**
   * @dev get the contract by index
   * @param _contractIndex uint of the index of the contract
   * @return (bytes32, address, uint) details of the contract
   */
  function getContractAtIndex(
    uint _contractIndex
  )
    public
    view
    returns (bytes32, address, uint)
  {

    SwapContractStruct storage tcs = contractStructs[contractIndex[_contractIndex]];
    return (
      tcs.name,
      tcs.contractAddress,
      tcs.index
    );
  }


  function stringToUint(bytes32 s) public pure returns (bytes32 result) {
    result = keccak256(abi.encode(s));
  }
}