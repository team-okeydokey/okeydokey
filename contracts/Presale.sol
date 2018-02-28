pragma solidity ^0.4.19;

import './SafeMath.sol';

interface OkeyDokeyToken {
    function transfer(address receiver, uint amount);
}

contract Presale {
    
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public weiRaised;
    uint256 public startTime;
    uint256 public deadline;
    uint256 public price;
    uint256 public bonusRate;
    OkeyDokeyToken public okeyDokeyToken;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event TokenRewarded(address backer, uint256 amount);
    event FundsWithdrawl(address team, uint256 amount);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Presale (
        address ifSuccessfulSendTo,
        uint256 fundingGoalInWei,
        uint256 durationInMinutes,
        uint256 pricePerTokenInWei,
        uint256 percentBonus,
        address addressOfTokenUsedAsReward
    ) {
        require(ifSuccessfulSendTo != address(0));
        require(addressOfTokenUsedAsReward != address(0));
        require(fundingGoalInWei > 0);
        require(durationInMinutes > 0);
        require(0 <= percentBonus && percentBonus <= 100);
        
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInWei;
        startTime = now;
        deadline = now + durationInMinutes * 1 minutes;
        price = pricePerTokenInWei;
        bonusRate = percentBonus;
        okeyDokeyToken = OkeyDokeyToken(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        require(!fundingGoalReached);
        require(now <= deadline);
        require(msg.value > 0);

        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        
        uint256 tokens;
        uint256 validWeiReceived;
        (tokens, validWeiReceived) = calculateReward(msg.sender, amount);
        
        weiRaised += validWeiReceived;
        okeyDokeyToken.transfer(msg.sender, tokens);
        TokenRewarded(msg.sender, amount);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function calculateReward(address sender, uint256 weiSent) internal returns (uint256 tokens, uint256 validWei) {
        require(sender != address(0));
        require(weiSent + weiRaised >= weiRaised); // Prevent overflow.
        
        uint256 totalReceived = weiSent + weiRaised;
        
        if (totalReceived >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, weiRaised);
            
            uint256 excess = totalReceived - fundingGoal; 
            validWei = weiSent - excess;
            
            // Send excess ether back.
            sender.transfer(excess);
        } else {
            validWei = weiSent;
        }
        
        // uint256 multiplier = (bonusRate + 100).div(100);
        // uint256 amountSentAfterBonus = validWei.mul(multiplier);
        // tokens = amountSentAfterBonus.div(price);
        tokens = weiSent.div(price);
    }

    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, sends the entire amount to the beneficiary.
     *
     */
    function withdraw() afterDeadline {

        if (beneficiary == msg.sender) {
            if (beneficiary.send(weiRaised)) {
                FundsWithdrawl(beneficiary, weiRaised);
            } 
        }
    }
}

