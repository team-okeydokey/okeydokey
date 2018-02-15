pragma solidity ^0.4.19;

import "./okeydokey.sol";
import "./houses.sol";

contract Reservations {

	/** Admin of this contract. */
    address private admin;

    /** Running count of reservation ids. Smallest valid reservation index is 1. */
    uint256 reservationId = 0;

    /** Map of house ids to each corresponding reservation. */
    mapping(uint256 => Reservation) private reservations;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Address of Houses contract. */
    address private housesAddress;

    /** Instance of Houses contract. */
    Houses private houses;

    /** Structure of a resevation. */
    struct Reservation {

        uint256 id;
        uint256 houseId;

        /* Reservation info */
        uint256 reservationCode;
        address host;
        address reserver;
        address[] guests;

        uint256 checkIn; /* Milliseconds since unix epoch */
        uint256 checkOut;

        /* Logistics */
        bool active;
    }

	/**
     * Modifier for functions only smart contract owner(admin) can run.
     */
    modifier system() {

        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only guests can run.
     *
     * @param id The id of reservation.
     */
    modifier onlyGuests(uint256 id) {

    	bool found = false;

    	/* Authorize host. */
    	if (reservations[id].host == msg.sender) {
    		found = true;
    	}

        /* Verify guest. */
        address[] storage guests = reservations[id].guests;
        for (uint256 i=0; i < guests.length; i++) {
            if (guests[i] == msg.sender) {
                found = true;
            }
        }

        require(found); 

        _;
    }

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
     *
     */
    function Reservations() public {
        admin = msg.sender;
    }

    /**
     * Initialize other OKDK contracts this contract depends on.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the initialization was successful.
     */
    function initializeContracts(address _okeyDokeyAddress) system public returns (bool success) {
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        housesAddress = okeyDokey.getAddress(1);
        houses = Houses(housesAddress);

        return true;
    }
		
    /**
     * Modifier for functions only house host(owner) can run.
     *
     * @param houseId The id of house to reserve.
     * @param checkIn Time of check in, in milliseconds since UNIX epoch.
     * @param checkOut Time of check out, in milliseconds since UNIX epoch.
     * @return success Whether the reservation was successful.
     * @return newId Id of the created reservation.
     */
	function reserve(uint256 houseId, uint256 checkIn, uint256 checkOut) 
		public returns (bool success, uint256 newId) {
        	
        success = false;
        newId = 0;

        /* Smallest houseId is 1 */
        reservationId += 1;

        Reservation memory reservation;

        /* Store reservation information. */
        reservation.id = reservationId;
        reservation.houseId = houseId;
        reservation.reserver = msg.sender;
        reservation.checkIn = checkIn;
        reservation.checkOut = checkOut;

        /* Fetch house information. */
        var (succ1, fetchedId, , host, active) = houses.getHouseInfo(houseId);

        if (!succ1 || !active || (fetchedId != houseId)) {
        	reservationId -= 1;
        	return;
        }
        
        /* Set host. */
        reservation.host = host;

        /* Assign reservation code. */
        var (succ2, reservationCode) 
            = generateReservationCode(msg.sender, host, reservationId);
        if (!succ2) {
        	reservationId -= 1;
        	return;
        }
        reservation.reservationCode = reservationCode;

        /* Add host as guest as well */
        reservations[reservation.id].guests.push(msg.sender);

        /* Save newly created house to storage. */
        reservations[reservation.id] = reservation;

        /* Logistics */
        reservation.active = true;

        newId = reservation.id;
        success = true;
	}

	/**
     * Modifier for functions only house host(owner) can run.
     *
     * @param host The first seed to randomize reservation code.
     * @param guest The second seed to randomize reservation code.
     * @param id The third seed to randomize reservation code.
     * @return success Whether the reservation was successful.
     * @return reservationCode Randomly generated reservation code.
     */
	function generateReservationCode(address host, address guest, uint256 id) 
        internal pure returns (bool success, uint256 reservationCode) {

		success = false;

		reservationCode = 244110;
		success = true;
	}

    /**
     * Fetch reservation information.
     *
     * @param _id The id of the reservation to query.
     * @return success Whether the query was successful.
     * @return id Id of the reservation.
     * @return reservationCode Randomly generated reservation code.
     * @return host Address of the host.
     * @return reserver Address of the reserver.
     * @return checkIn Time of check in, in milliseconds since UNIX epoch.
     * @return checkOut Time of check out, in milliseconds since UNIX epoch.
     * @return active Whether the listing is active.
     */
    function getHouseInfo(uint256 _id) public view onlyGuests(_id)
        returns (bool success, uint256 id, uint256 reservationCode, 
                 address host, address reserver, 
                 uint256 checkIn, uint256 checkOut, bool active) {

        success = false;

        Reservation storage reservation = reservations[_id]; 

        id = reservation.id;
        reservationCode = reservation.reservationCode;
        host = reservation.host;
        reserver = reservation.reserver;
        checkIn = reservation.checkIn;
        checkOut = reservation.checkOut;
        active = reservation.active;

        success = true;
    } 
}