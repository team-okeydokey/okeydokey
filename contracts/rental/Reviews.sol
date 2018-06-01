pragma solidity ^0.4.19;

import "../core/OkeyDokey.sol";
import "./Reservations.sol";

contract Reviews {

	/** Admin of this contract. */
    address private admin;

    /** Running count of review ids. Smallest valid review index is 1. */
    uint256 reviewId = 0;

    /** Map of review ids to each corresponding review. */
    mapping(uint256 => Review) private reviews;

    /** Map of address to its authored reviews. */
    mapping(address => uint256[]) private reviewsBy;

    /** Map of house id to review ids. */
    mapping(uint256 => uint256[]) private reviewsFor;

    /** Address of OkeyDokey contract. */
    address private okeydokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeydokey;

    /** Address of Reservations contract. */
    address private reservationsAddress;

    /** Instance of Reservations contract. */
    Reservations private reservations;

	/** Structure of a reservation. */
    struct Review {
        uint256 id;
        uint256 houseId;
        uint256 reservationId;
        address reviewer;
        uint8 rating; /* Rating on a scale of 0 to 10 */
        bytes content;
        bool valid;
    }

    /**
     * Modifier for functions only smart contract owner(admin) can run.
     */
    modifier OkeyDokeyAdmin() {

        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only OkeyDokey smart contracts can run.
     * 
     * @param addr The address to check.
     */
    modifier system(address addr) {

        /* Verify admin. */
        require(okeydokey.isAdmin(addr));

        _;
    }

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
     *
     */
    function Reviews() public {
        admin = msg.sender;
    }

	/**
     * Initialize other OKDK contracts this contract depends on.
     *
     * @param _okeydokeyAddress The address of main application contract.
     * @return success Whether the initialization was successful.
     */
    function initializeContracts(address _okeydokeyAddress) 
        OkeyDokeyAdmin public returns (bool success) {
        require(_okeydokeyAddress != address(0));
        require(_okeydokeyAddress != address(this));

        okeydokeyAddress = _okeydokeyAddress;
        okeydokey = OkeyDokey(okeydokeyAddress);

        reservationsAddress = okeydokey.getAddress(3);
        reservations = Reservations(reservationsAddress);

        return true;
    }

    /**
     * Submit a review.
     *
     * @param reservationId The id of reservation being reviewed.
     * @param rating The rating of the review, on a scale of 0 to 10.
     * @param content The content of the review.
     * @return success Whether submission of the review was successful.
     * @return newId Id of the created review.
     */
    function submitReview(uint256 reservationId, uint8 rating, bytes content) 
        public returns (bool success, uint256 newId) {

        require(reservationId > 0);
            
        success = false;
        newId = 0;

        /* Smallest reviewId is 1 */
        reviewId += 1;

        Review memory review;

        /* Fetch reservation information and check if msg,sender is authorized. */
        bool succ;
        uint256 resId;
        uint256 houseId;

        (succ, resId, houseId, , , , ,) = reservations.getReservationInfo(reservationId);
        bool correctId = reservationId == resId;

        if (!correctId) {
            reservationId -= 1;
            return;
        }

        /* Store reservation information. */
        review.id = reviewId;
        review.houseId = houseId;
        review.reservationId = reservationId;
        review.reviewer = msg.sender;
        review.rating = rating;
        review.content = content;

 		/* Logistics */
        review.valid = true;

        /* Save newly created house to storage. */
        reviews[review.id] = review;
        reviewsBy[msg.sender].push(review.id);
        reviewsFor[houseId].push(review.id);

        /* Reward process. */

        newId = review.id;
        success = true;
    }

    /**
     * Self destruct.
     */
    function kill() OkeyDokeyAdmin public { 
        selfdestruct(admin); 
    }

}
