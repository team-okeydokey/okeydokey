pragma solidity ^0.4.19;

import "../libs/IterableMapping.sol";

/**
 * @title Whitelist
 * @dev Store whitelisted user ids and addresses.
 */
contract Whitelist {
    using IterableMapping for IterableMapping.itmap;

    /* Creator of this ICO contract. */
    address owner;

    /* Whitelist with all users that can contribute to this ico. */
    IterableMapping.itmap private whitelist;

    /* Add list of contracts that can access this contract. */
    mapping (address => bool) private approvedAddresses;

    /* Address to its user id. */
    mapping (address => bytes32) private idOf;

    /**
     * @dev Reverts if not in crowdsale time range.  
     */
    modifier onlyOwner() {
        require(owner != address(0));
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Reverts if not in crowdsale time range.  
     */
    modifier system() {
        require(owner != address(0));
        require(msg.sender == owner
          || approvedAddresses[msg.sender]);
        _;
    }
    
    /**
     * @dev Constructor, takes all necessary arguments.
     */
    function Whitelist() public {
        owner = msg.sender;
    }

    /**
     * @dev Sets access level of an address. 
     * @param _address Address to set permissions to access whitelist
     * @param _hasAccess Whether the address has access
     */
    function setApproval(address _address, bool _hasAccess) onlyOwner public {
      approvedAddresses[_address] = _hasAccess;
    }

    /**
     * @dev Deliver tokens to an individual user.
     * @param _id Id of the user
     * @return Index of id within whitelist.
     */
    function indexOf(bytes32 _id) public view returns (uint) {
      require(_idInWhitelist(_id));

      return whitelist.data[_id].keyIndex - 1;
    }

    /**
     * @dev Getter for whitelist size.
     * @return Size of whitelist.
     */
    function whitelistSize() public view returns (uint) {
      return whitelist.size;
    }

    /**
     * @dev Getter for user id in ith index.
     * @param _index Index of user in  whitelist.
     * @return bytes32 user id.
     * @return Addresses associated with user id.
     */
    function idInIndex(uint _index) public view 
      returns (bytes32, address[5]) {

      return IterableMapping.iterate_get(whitelist, _index);
    }

    /**
     * @dev Checks whether id was registered to whitelist. 
     * @param _id Id of user.
     * @return Whether the id exists in whitelist.
     */
    function idInWhitelist(bytes32 _id) public view 
      returns (bool) {

      return _idInWhitelist(_id);
    }

    /**
     * @dev Checks whether address was registered to whitelist. 
     * @param _address Address of user.
     * @return Whether the address exists in whitelist.
     */
    function addressInWhitelist(address _address) public view 
      returns (bool) {

      return _addressInWhitelist(_address);
    }

    /**
     * @dev Add user to whitelist
     * @param _id Id of user to whitelist
     * @param _address Address of user to whitelist
     * @param _index Index, from 0 to 4, indicating which address to modify.
     */
    function whitelistAddress(bytes32 _id, address _address, uint _index) 
      public system {

      _whitelistAddress(_id, _address, _index);
    }

    /**
     * @dev Add user to whitelist
     * @param _ids Id of user to whitelist
     * @param _addresses Address of user to whitelist
     * @param _indices Index, from 0 to 4, indicating which address to modify.
     */
    function whitelistAddresses(bytes32[] _ids, address[] _addresses, uint[] _indices) 
      public system {

      _whitelistAddresses(_ids, _addresses, _indices);
    }

    /**
     * @dev Remove address from whitelist
     * @param _address Address of user to unwhitelist
     */
    function unWhitelistAddress(address _address) 
      public system {

      _unWhitelistAddress(_address);
    }

    /**
     * @dev Add user to whitelist
     * @param _id User id to whitelist
     * @param _address Address of user to whitelist
     * @param _index Index, from 0 to 4, indicating which address to modify.
     */
    function _whitelistAddress(bytes32 _id, address _address, uint _index) 
      internal {

      require(_id != 0x0);
      require(_address != address(0));
      require(0 <= _index && _index < 5);
      require(!_addressInWhitelist(_address));

      // Fetch old entry.
      if (_idInWhitelist(_id)) {

        address[5] storage addresses = whitelist.data[_id].value;

        address prevAddr = addresses[_index];

        // Update address list.
        addresses[_index] = _address;

        // Remove previous address.
        if (prevAddr != address(0)) {
          idOf[prevAddr] = 0x0;
        }
        
      // Create new entry.
      } else {
        address[5] memory newAddresses;
        // newAddresses[0] = __addressid;
        newAddresses[_index] = _address;
        IterableMapping.insert(whitelist, _id, newAddresses);
      }

      // Map address to its id.
      idOf[_address] = _id;
    }

    /**
     * @dev Add user to whitelist
     * @param _ids User id to whitelist
     * @param _addresses Address of user to whitelist
     * @param _indices Index, from 0 to 4, indicating which address to modify.
     */
    function _whitelistAddresses(bytes32[] _ids, address[] _addresses, uint[] _indices) 
      internal {

      require(_ids.length > 0);
      require(_ids.length == _addresses.length && _addresses.length == _indices.length);

      for (uint i=0; i < _ids.length; i++) {
        _whitelistAddress(_ids[i], _addresses[i], _indices[i]);
      }
    }


    /**
     * @dev Remove address from whitelist
     * @param _address Address of user to unwhitelist
     */
    function _unWhitelistAddress(address _address) 
      internal {

      require(_address != address(0));
      require(_addressInWhitelist(_address));

      bytes32 id = idOf[_address];

      address[5] storage addresses = whitelist.data[id].value;

      for (uint i=0; i < addresses.length; i++) {
        if (addresses[i] == _address) {
          addresses[i] = address(0);
        }
      }

      // Map address to its id.
      idOf[_address] = 0x0;
    }

    /**
     * @dev Get addresses listed under id
     * @param _id Id to fetch addresses for
     * @return Addresses (max of 5).
     */
    function addressesOf(bytes32 _id) system 
      public view returns (address[5]) {

      return _addressesOf(_id);
    }

    /**
     * @dev Check if an address is in whitelist
     * @param _address Address to check for
     * @return True if in whitelist
     */
    function _addressInWhitelist(address _address) 
      internal view returns (bool) {

      require(_address != address(0));

      bytes32 id = idOf[_address]; 

      if (id != 0x0) {

        address[5] memory addresses = _addressesOf(id);

        for (uint i=0; i < addresses.length; i ++) {
          if (addresses[i] == _address) {
            return true;
          }
        }
      } 

      return false;
    }

    /**
     * @dev Check if a user id is in whitelist
     * @param _id Id to check for.
     * @return True if in whitelist
     */
    function _idInWhitelist(bytes32 _id) 
      internal view returns (bool) {

      if (_id == 0x0) {
        return false;
      }

      return IterableMapping.contains(whitelist, _id);
    }

    /**
     * @dev Get addresses listed under id
     * @param _id Id to fetch addresses for
     * @return Addresses (max of 5).
     */
    function _addressesOf(bytes32 _id) 
      internal view returns (address[5]) {

      require(_idInWhitelist(_id));

      return whitelist.data[_id].value;
    }
}