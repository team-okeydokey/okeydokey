pragma solidity ^0.4.19;

import "../libs/SafeMath.sol";
import "./Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract OkeyDokeySale is Crowdsale {
    using SafeMath for uint256; 

    mapping (address => uint256) public contributionOf;

    uint256 public cap;
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
     * @dev Constructor, takes all necessary arguments.
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     * @param _cap Max amount of wei to be contributed
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function OkeyDokeySale(uint256 _rate, address _wallet, KeyToken _token, 
                           uint256 _cap, uint256 _openingTime, uint256 _closingTime) 
                           Crowdsale(_rate, _wallet, _token) public {
        require(_cap > 0);
        require(_closingTime > _openingTime);

        cap = _cap;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the cap has been reached. 
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
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
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
      // Prevent overflow.
      require(contributionOf[_beneficiary] + _weiAmount >= contributionOf[_beneficiary]); 

      uint256 initialAmount = contributionOf[_beneficiary];

      contributionOf[_beneficiary] += _weiAmount;

      require(initialAmount + _weiAmount == contributionOf[_beneficiary]);
    }

}