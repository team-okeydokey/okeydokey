pragma solidity ^0.4.19;

import "../libs/SafeMath.sol";
import "../libs/IterableMapping.sol";
import "./Crowdsale.sol";

/**
 * @title OkeyDokeySale
 * @dev Crowdsale accepting contributions only within a time frame and under a cap.
 */
contract OkeyDokeySale is Crowdsale {
    using SafeMath for uint256; 
    using IterableMapping for IterableMapping.itmap;

    /* Creator of this ICO contract. */
    address owner;

    /* Admin of this ICO contract. */
    address admin;

    /* Whitelist with all users that can contribute to this ico. */
    IterableMapping.itmap private whitelist;

    /* Address to its user id. */
    mapping (address => bytes32) private idOf; 

    /* User id to amount of wei contributed. */
    mapping (bytes32 => uint256) public contributionOf;

    /* User id to amount of tokens rewarded. */
    mapping (bytes32 => uint256) public tokensOf;

    /* User id to amount of referral bonus rewarded. */
    mapping (bytes32 => uint256) public bonusTokensOf;

    /* User id to address that provided the referral link for an address. */
    mapping (bytes32 => bytes32) public referrerOf;

    uint256 public tokensSold;
    uint256 public bonusTokensSold;
    uint256 public tokenCap;
    uint256 public bonusCap;
    uint256 public bonusRate;
    uint256 public openingTime;
    uint256 public closingTime;

    /**
     * @dev Reverts if not in crowdsale time range. 
     */
    modifier onlyWhileOpen {
        require(openingTime <= now && now <= closingTime);

        // Allow last purchase that overshoots sale goal.
        require(!capReached());
        _;
    }

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
    modifier onlyAdmin() {
        require(owner != address(0));
        require(admin != address(0));
        require(msg.sender == owner || msg.sender == admin);
        _;
    }
    
    /**
     * @dev Constructor, takes all necessary arguments.
     * @param _rate Number of token units a buyer gets per wei
     * @param _bonusRate Number of token units a awarded as referral bonus per wei
     * @param _admin Address that can whitelist addresses
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     * @param _tokenCap Max amount of tokens to sell
     * @param _bonusCap Max amount of tokens a referrer can receive as bonus
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function OkeyDokeySale(uint256 _rate, uint256 _bonusRate, 
                           address _admin, address _wallet, 
                           OkeyToken _token, uint256 _tokenCap, uint256 _bonusCap,
                           uint256 _openingTime, uint256 _closingTime) 
                           Crowdsale(_rate, _wallet, _token) public {
        require(_tokenCap > 0);
        require(_closingTime > _openingTime);

        owner = msg.sender;
        admin = _admin;
        tokenCap = _tokenCap;
        bonusCap = _bonusCap;
        bonusRate = _bonusRate;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Sets new admin. 
     */
    function setAdmin(address _admin) onlyOwner public {
      require(_admin != address(0));

      admin = _admin;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) 
      internal onlyWhileOpen {

      super._preValidatePurchase(_beneficiary, _weiAmount);

      // Only allow contributions from whitelisted addresses.
      require(_addressInWhitelist(_beneficiary));
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
      _updateTokenBalanceState(_beneficiary, _weiAmount);
      _updateContributionState(_beneficiary, _weiAmount);
    }

    /**
     * @dev Set token balance after purchase.
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updateTokenBalanceState(address _beneficiary, uint256 _weiAmount) internal {

      // Fetch id.
      bytes32 id = idOf[_beneficiary];

      // Calculate and add token balance.
      uint256 newTokens = _getTokenAmount(_weiAmount);
      tokensOf[id] = tokensOf[id].add(newTokens);

      tokensSold = tokensSold.add(newTokens);

      // Calculate and award referral bonus, if applicable.
      bool eligible;
      bytes32 referrer;
      (eligible, referrer) = _hasReferrer(id);

      if (eligible) {

        // Calculate bonus tokens.
        uint256 newBonusTokens = _getBonusTokenAmount(_weiAmount);

        // Update token buyer's bonus tokens.
        bonusTokensOf[id] = bonusTokensOf[id].add(newBonusTokens);
        bonusTokensSold = bonusTokensSold.add(newBonusTokens);

        // Calculate referrer's bonus tokens.
        uint256 referrerBonusTokens;
        if (bonusTokensOf[referrer] >= bonusCap) {
          referrerBonusTokens = 0;
        } else if (bonusTokensOf[referrer].add(newBonusTokens) >= bonusCap) {
          referrerBonusTokens = bonusCap.sub(bonusTokensOf[referrer]);
        } else {
          referrerBonusTokens = newBonusTokens;
        }

        // Update referrer's bonus tokens. 
        bonusTokensOf[referrer] = bonusTokensOf[referrer].add(referrerBonusTokens);
        bonusTokensSold = bonusTokensSold.add(referrerBonusTokens);
      }

    }

    /**
     * @dev Set contribution log after purchase.
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updateContributionState(address _beneficiary, uint256 _weiAmount) internal {
      // Prevent overflow.      
      bytes32 id = idOf[_beneficiary];
      contributionOf[id] = contributionOf[id].add(_weiAmount);
    }

    /**
     * @dev Calculate bonus token amount.
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _getBonusTokenAmount(uint256 _weiAmount) 
      internal view returns (uint256) {

      return _weiAmount.mul(bonusRate);
    }

    /**
     * @dev Recover funds in an emergency.
     */
    function recoverFunds() onlyAdmin public {
        _deliverTokens(owner, token.balanceOf(address(this))); 
    }

    /**
     * @dev Deliver tokens to an individual user.
     * @param _id Id of the user.
     * @param _address Address to deliver tokens to.
     */
    function releaseTokens(bytes32 _id, address _address) public onlyAdmin {
      require(_idInWhitelist(_id));
      // require(idOf[_address] == _id);

      _deliverTokens(_address, tokensOf[_id].add(bonusTokensOf[_id]));
    }

    /**
     * @dev Get index of id within whitelist.
     * @param _id Id of the user
     * @return Index of id within whitelist.
     */
    function indexOf(bytes32 _id) public onlyAdmin returns (uint) {
      require(_idInWhitelist(_id));

      return whitelist.data[_id].keyIndex - 1;
    }

    /* Referral functions */

    /**
     * @dev Add a referrer of an address.
     * @param _referee Id of person who clicked the link
     * @param _referrer Id of provider of referral link
     */
    function addReferrer(bytes32 _referee, bytes32 _referrer) 
      onlyAdmin public {
      require(_referee != 0x0);
      require(_referrer != 0x0);
     
      require(_idInWhitelist(_referee));
      require(_idInWhitelist(_referrer));

      referrerOf[_referee] = _referrer;
    }

    /**
     * @dev Check if a sale is eligible for referral bonus.
     * @param _id Id that sent ether
     * @return _eligible True if eligible
     * @return _referrer Id of referrer
     */
    function _hasReferrer(bytes32 _id) 
      internal view returns (bool _eligible, bytes32 _referrer) {

      require(_id != 0x0);

      _eligible = false;
      _referrer = referrerOf[_id];

      if (_referrer != 0x0) {
        _eligible = true;
      }
    }

    /* Sale status functions */

    /**
     * @dev Checks whether the cap has been reached. 
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return tokensSold.add(bonusTokensSold) >= tokenCap;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return now > closingTime;
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
    function idInIndex(uint _index) public view onlyAdmin 
      returns (bytes32, address[5]) {

      return IterableMapping.iterate_get(whitelist, _index);
    }

    /**
     * @dev Checks whether id was registered to whitelist. 
     * @param _id Id of user.
     * @return Whether the id exists in whitelist.
     */
    function idInWhitelist(bytes32 _id) public view onlyAdmin 
      returns (bool) {

      return _idInWhitelist(_id);
    }

    /**
     * @dev Checks whether address was registered to whitelist. 
     * @param _address Address of user.
     * @return Whether the address exists in whitelist.
     */
    function addressInWhitelist(address _address) public view onlyAdmin 
      returns (bool) {

      return _addressInWhitelist(_address);
    }

    /**
     * @dev Checks whether an id has a referrer. 
     * @param _id Id of user.
     * @return Whether the id has a referrer.
     * @return Id of the referrer.
     */
    function hasReferrer(bytes32 _id) public view onlyAdmin 
      returns (bool, bytes32) {

      return _hasReferrer(_id);
    }

    /* Whitelist functions */

    /**
     * @dev Add user to whitelist
     * @param _id Id of user to whitelist
     * @param _address Address of user to whitelist
     * @param _index Index, from 0 to 4, indicating which address to modify.
     */
    function whitelistAddress(bytes32 _id, address _address, uint8 _index) 
      public onlyAdmin {

      _whitelistAddress(_id, _address, _index);
    }

    /**
     * @dev Add user to whitelist
     * @param _ids Id of user to whitelist
     * @param _addresses Address of user to whitelist
     * @param _indices Index, from 0 to 4, indicating which address to modify.
     */
    function whitelistAddresses(bytes32[] _ids, address[] _addresses, uint8[] _indices) 
      public onlyAdmin {

      _whitelistAddresses(_ids, _addresses, _indices);
    }

    /**
     * @dev Remove address from whitelist
     * @param _address Address of user to unwhitelist
     */
    function unWhitelistAddress(address _address) 
      public onlyAdmin {

      _unWhitelistAddress(_address);
    }

    /**
     * @dev Add user to whitelist
     * @param _id User id to whitelist
     * @param _address Address of user to whitelist
     * @param _index Index, from 0 to 4, indicating which address to modify.
     */
    function _whitelistAddress(bytes32 _id, address _address, uint8 _index) 
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
    function _whitelistAddresses(bytes32[] _ids, address[] _addresses, uint8[] _indices) 
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
    function addressesOf(bytes32 _id) onlyAdmin 
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