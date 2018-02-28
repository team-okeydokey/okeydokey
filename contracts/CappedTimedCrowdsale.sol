pragma solidity ^0.4.19;

import "./SafeMath.sol";
import "./Crowdsale.sol";


/**
 * @title CappedTimedCrowdsale
 * @dev Crowdsale with a limit for total contributions within a set time period.
 */
contract CappedTimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;
  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range. 
   */
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes max contribution amount and time frame.
   * @param _cap Max amount of wei to be contributed
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function CappedTimedCrowdsale(uint256 _cap, uint256 _openingTime, uint256 _closingTime) public {
    require(_cap > 0);
    require(_closingTime >= _openingTime);

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

}
