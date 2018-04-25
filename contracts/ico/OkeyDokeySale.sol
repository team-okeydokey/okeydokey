pragma solidity ^0.4.19;

import "../libs/SafeMath.sol";
import "../libs/IterableMapping.sol";
import "./Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract OkeyDokeySale is Crowdsale {
    using SafeMath for uint256; 

    /* Creator of this ICO contract. */
    address owner;

    /* Admin of this ICO contract. */
    address admin;

    /* Whitelist with all users that can contribute to this ico. */
    IterableMapping.itmap public whitelist;

    /* Amount of wei contributed. */
    mapping (address => uint256) public contributionOf;

    /* Amount of tokens rewarded. */
    mapping (address => uint256) public tokensOf;

    /* Amount of referral bonus rewarded. */
    mapping (address => uint256) public bonusTokensOf;

    /* Address that provided the referral link for an address. */
    mapping (address => address) public referrerOf;

    uint256 public tokensSold;
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
        require(admin != address(0));
        require(msg.sender == admin);
        _;
    }
    
    /**
     * @dev Constructor, takes all necessary arguments.
     * @param _rate Number of token units a buyer gets per wei
     * @param _admin Address that can whitelist addresses. 
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     * @param _tokenCap Max amount of tokens to sell
     * @param _bonusCap Max amount of referral bonus to award to an individual
     * @param _bonusRate Number of token units a awarded as referral bonus per wei
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function OkeyDokeySale(uint256 _rate, address _admin, address _wallet, OkeyToken _token, 
                           uint256 _tokenCap, uint256 _bonusCap, uint256 _bonusRate,
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
    function setAdmin(address _admin) onlyOwner {
      require(_admin != address(0));

      admin = _admin;
    }

    /**
     * @dev Checks whether the cap has been reached. 
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return tokensSold >= tokenCap;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) 
      internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        
        require(whitelist.data[_beneficiary].value);
        require(tokensSold.add(_getTokenAmount(_weiAmount)) <= tokenCap);
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

      // Calculate and add token balance.
      uint256 initialTokens = tokensOf[_beneficiary];
      uint256 newTokens = _getTokenAmount(_weiAmount);
      tokensOf[_beneficiary] = initialTokens.add(newTokens);

     // Calculate and award referral bonus, if applicable.
     bool hasReferrer;
     address referrer;
     (hasReferrer, referrer) = _hasReferrer(_beneficiary);
     if (hasReferrer) {
        // Update token buyer's bonus tokens.
        uint256 initialBonus = bonusTokensOf[_beneficiary];
        uint256 newBonusTokens = _weiAmount.mul(bonusRate);

        if (initialBonus.add(newBonusTokens) >= bonusCap) {
          bonusTokensOf[_beneficiary] = bonusCap;
        } else {
          bonusTokensOf[_beneficiary] = bonusTokensOf[_beneficiary].add(newBonusTokens);
        }

        // Update referrer's bonus tokens.
        uint256 initialBonusR = bonusTokensOf[referrer];
        uint256 newBonusTokensR = _weiAmount.mul(bonusRate);

        if (initialBonusR.add(newBonusTokensR) >= bonusCap) {
          bonusTokensOf[referrer] = bonusCap;
        } else {
          bonusTokensOf[referrer] = bonusTokensOf[referrer].add(newBonusTokensR);
        }
      }

    }

    /**
     * @dev Set contribution log after purchase.
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updateContributionState(address _beneficiary, uint256 _weiAmount) internal {
      // Prevent overflow.      
      contributionOf[_beneficiary] = contributionOf[_beneficiary].add(_weiAmount);
    }

    /**
     * @dev Calculate bonus token amount.
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _getBonusTokenAmount(address _beneficiary, uint256 _weiAmount) 
      internal view returns (uint256) {

      require(_beneficiary != address(0));
      require(referrerOf[_beneficiary] != address(0));

      return _weiAmount.mul(bonusRate);
    }

    /**
     * @dev Add user to whitelist.
     * @param _user Address of user to whitelist.
     */
    function whitelistAddress(address _user) public onlyAdmin {
      require(_user != address(0));

      IterableMapping.insert(whitelist, _user, true);
    }

    /**
     * @dev Remove user from whitelist.
     * @param _user Address of user to whitelist.
     */
    function unWhitelistAddress(address _user) public onlyAdmin {
      require(_user != address(0));

     IterableMapping.insert(whitelist, _user, false);
    }

    /**
     * @dev Release tokens. Must be called by the address that received ether.
     */
    function releaseTokens() public {

      require(msg.sender == wallet);

      for (uint256 i = IterableMapping.iterate_start(whitelist); 
        IterableMapping.iterate_valid(whitelist, i); 
        i = IterableMapping.iterate_next(whitelist, i)) {

        address beneficiary;
        (beneficiary, ) = IterableMapping.iterate_get(whitelist, i);

        uint256 tokens = tokensOf[beneficiary].add(bonusTokensOf[beneficiary]);
        _deliverTokens(beneficiary, tokens);
      }
    }

    /**
     * @dev Add a referrer of an address.
     * @param _referrer Provider of referral link
     * @param _referee Person who clicked the link
     */
    function addReferrer(address _referrer, address _referee) 
      onlyAdmin public {
      require(_referrer != address(0));
      require(_referee != address(0));

      require(whitelist.data[_referrer].value);
      require(whitelist.data[_referee].value);

      referrerOf[_referee] = _referrer;
    }

    /**
     * @dev Check if a sale is eligible for referral bonus.
     * @param _beneficiary Address that sent ether
     * @return _eligible True if eligible
     * @return _referrer Address of referrer
     */
    function _hasReferrer(address _beneficiary) 
      internal returns (bool _eligible, address _referrer) {

      require(_beneficiary != address(0));

      _eligible = false;
      _referrer = referrerOf[_beneficiary];

      if (_referrer != address(0)) {
        _eligible = true;
      }

    }

}