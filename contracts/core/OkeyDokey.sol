pragma solidity ^0.4.19;

contract OkeyDokey {

  /** Contract codes */
  uint constant public TOKEN = 0;
  uint constant public MARKET = 100;
  uint constant public TRANSACTION_DATABASE = 101; 

  /** Owner of this contract. */
  address private owner;

  /* Add list of contracts that has admin access to this contract. */
  mapping (address => bool) public adminAccess;

  /** Running count of contracts in the OkeyDokey ecosystem. */
  uint16 public contractCount = 0;

  /** Address of contracts. 
   * 
   * 0 - OkeyDokeyToken.
   * 1 ~ 99 - Important contracts.
   * 100 ~ 199 - Internal libraries.
   * 200 ~ 999 - Other internal libraries.
   * 1000 ~ Maximum uint - Application ids.
   *
   */
  mapping (uint => address) private addresses;

  /** 
   * Only owner can call.
   */
  modifier onlyOwner() {
    require(owner != address(0));
    require(msg.sender == owner);

    _;
  }

  /** 
   * Only admins can call.
   */
  modifier onlyAdmin() {
    require(adminAccess[msg.sender]);

    _;
  }

  /**
   * Constrctor function.
   *
   * Set the owner.
   */
  function OkeyDokey() public {
    owner = msg.sender;
  }

  /**
   * Transfer ownership of contract.
   *
   * @param _newOwner The address of the potential new owner
   */
  function transferOwnership(address _newOwner) onlyOwner public {
    require(_newOwner != address(0));

    owner = _newOwner;
  }

  /**
   * @dev Sets access level of an address. 
   * @param _address Address to set admin permissions
   * @param _hasAccess Whether the address has admin access
   */
  function setAdmin(address _address, bool _hasAccess) onlyOwner public {
    adminAccess[_address] = _hasAccess;
  }

  /**
   * @dev Gets access level of an address. 
   * @param _address Address to get admin permissions
   * @return Whether the address has admin access
   */
  function isAdmin(address _address) public returns (bool) {
    return adminAccess[_address];
  }

  /**
   * Return address of contracts.
   *
   * @param _tag The identifying tag of the contract
   * @return Address of contract with tag
   */
  function getAddress(uint _tag) public view returns (address) {
    return addresses[_tag];
  }

  /**
   * Update address of contracts.
   *
   * @param _tag The identifying tag of the new contract
   * @param _newAddress The address of the new contract
   */
  function updateAddress(uint _tag, address _newAddress) public onlyOwner {
    require(_newAddress != 0x0);

    if (addresses[_tag] == 0x0) {
      /* New contract. */
      contractCount += 1;
    }

    addresses[_tag] = _newAddress;
  }

  /**
   * Self destruct.
   */
  function kill() onlyOwner public { 
    if (msg.sender == owner) selfdestruct(owner); 
  }

}