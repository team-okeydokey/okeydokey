pragma solidity ^0.4.19;

import "../libs/SafeMath.sol";
import "./Whitelist.sol";
import "./Referral.sol";
import "./Crowdsale.sol";

/**
 * @title OkeyDokeySale
 * @dev Crowdsale accepting contributions only within a time frame and under a cap.
 */
contract OkeyDokeySale is Crowdsale {
    using SafeMath for uint256; 

    /* Creator of this ICO contract. */
    address owner;

    /* Admin of this ICO contract. */
    address admin;

    /* User id to amount of wei contributed. */
    mapping (bytes32 => uint256) public contributionOf;

    /* User id to amount of tokens rewarded. */
    mapping (bytes32 => uint256) public tokensOf;

    /* User id to amount of referral bonus rewarded. */
    mapping (bytes32 => uint256) public bonusTokensOf;

    Whitelist private whitelist;
    Referral private referral;
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
     * @dev Reverts if not in owner status.    
     */
    modifier onlyOwner() {
        require(owner != address(0));
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Reverts if not in admin status.  
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
     * @param _whitelist Address of whitelist contract
     * @param _referral Address of referral contract
     * @param _tokenCap Max amount of tokens to sell
     * @param _bonusCap Max amount of tokens a referrer can receive as bonus
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function OkeyDokeySale(uint256 _rate, uint256 _bonusRate, 
                           address _admin, address _wallet, 
                           Whitelist _whitelist, Referral _referral,
                           OkeyToken _token, uint256 _tokenCap, uint256 _bonusCap,
                           uint256 _openingTime, uint256 _closingTime) 
                           Crowdsale(_rate, _wallet, _token) public {
        require(_tokenCap > 0);
        require(_closingTime > _openingTime);

        owner = msg.sender;
        admin = _admin;
        whitelist = _whitelist;
        referral = _referral;
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
      require(whitelist.addressInWhitelist(_beneficiary));
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
      bytes32 id = whitelist.getIdOf(_beneficiary);

      // Calculate and add token balance.
      uint256 newTokens = _getTokenAmount(_weiAmount);
      tokensOf[id] = tokensOf[id].add(newTokens);

      tokensSold = tokensSold.add(newTokens);

      // Calculate and award referral bonus, if applicable.
      bool eligible;
      bytes32 referrer;
      (eligible, referrer) = referral.hasReferrer(id);

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
      bytes32 id = whitelist.getIdOf(_beneficiary);
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
     * @dev Recover funds from ico contract.
     */
    function recoverTokens() onlyAdmin public {
        _deliverTokens(owner, token.balanceOf(address(this))); 
    }

    /**
     * @dev Deliver tokens to an individual user.
     * @param _id Id of the user.
     * @param _address Address to deliver tokens to.
     */
    function releaseTokens(bytes32 _id, address _address) public onlyAdmin {
      require(whitelist.idInWhitelist(_id));
      // require(idOf[_address] == _id);

      _deliverTokens(_address, tokensOf[_id].add(bonusTokensOf[_id]));
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
}