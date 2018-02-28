pragma solidity ^0.4.19;

import "./SafeMath.sol";
import "./Crowdsale.sol";
import "./CappedTimedCrowdsale.sol";


/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract OkeyDokeySale is CappedTimedCrowdsale {
    using SafeMath for uint256; 

    /**
     * @dev Constructor, takes all necessary arguments.
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     * @param _cap Max amount of wei to be contributed
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function OkeyDokeySale(uint256 _rate, address _wallet, OkeyDokeyToken _token, 
                           uint256 _cap, uint256 _openingTime, uint256 _closingTime) 
             CappedTimedCrowdsale(_cap, _openingTime, _closingTime)
             Crowdsale(_rate, _wallet, _token) public {
    }

}