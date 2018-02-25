pragma solidity ^0.4.19;

import './SafeMath.sol';

interface OkeyDokeyToken {
    function transfer(address receiver, uint amount);
}

contract Presale {
    
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public startTime;
    uint256 public deadline;
    uint256 public price;
    uint256 public bonusRate;
    OkeyDokeyToken public okeyDokeyToken;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event TokenRewarded(address backer, uint256 amount);
    event FundsWithdrawl(address team, uint256 amount);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Presale(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        uint256 durationInMinutes,
        uint256 etherCostOfEachToken,
        uint256 percentBonus,
        address addressOfTokenUsedAsReward
    ) {
        require(ifSuccessfulSendTo != address(0));
        require(addressOfTokenUsedAsReward != address(0));
        require(fundingGoalInEthers > 0);
        require(durationInMinutes > 0);
        require(0 <= percentBonus && percentBonus <= 100);
        
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        startTime = now;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        bonusRate = percentBonus;
        okeyDokeyToken = OkeyDokeyToken(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        require(!crowdsaleClosed);
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        
        uint256 tokens;
        uint256 validEtherReceived;
        (tokens, validEtherReceived) = calculateReward(msg.sender, amount);
        
        amountRaised += validEtherReceived;
        okeyDokeyToken.transfer(msg.sender, tokens);
        TokenRewarded(msg.sender, amount);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function calculateReward(address sender, uint256 amountSent) internal returns (uint256 tokens, uint256 validEther) {
        require(sender != address(0));
        require(amountSent + amountRaised >= amountRaised); // Prevent overflow.
        
        uint256 totalReceived = amountSent + amountRaised;
        
        if (totalReceived >= fundingGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            GoalReached(beneficiary, amountRaised);
            
            uint256 excess = totalReceived - fundingGoal; 
            validEther = amountSent - excess;
            
            // Send excess ether back.
            sender.transfer(excess);
        } else {
            validEther = amountSent;
        }
        
        uint256 multiplier = (bonusRate + 100).div(100);
        uint256 amountSentAfterBonus = validEther.mul(multiplier);
        tokens = amountSentAfterBonus.div(price);
    }

    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, sends the entire amount to the beneficiary.
     *
     */
    function withdraw() afterDeadline {

        if (beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundsWithdrawl(beneficiary, amountRaised);
            } 
        }
    }
}

