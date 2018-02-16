pragma solidity ^0.4.19;

import "./okeydokey.sol";
import "./houses.sol";

contract Reservations {

    /** Admin of this contract. */
    address private admin;

    /** Running count of reservation ids. Smallest valid reservation index is 1. */
    uint256 reservationId = 0;

    /** Map of reservation ids to each corresponding reservation. */
    mapping(uint256 => Reservation) private reservations;

    /** Map of reservation code to each corresponding reservation. */
    mapping(bytes32 => uint256) private reservationCodes;

    /** Map of address to its reservations. */
    mapping(address => uint256[]) private reservationsBy;

    /** Map of house id to reservation ids. */
    mapping(uint256 => uint256[]) private reservationsAt;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Address of Houses contract. */
    address private housesAddress;

    /** Instance of Houses contract. */
    Houses private houses;

    /** Lifecycle of a reservation */
    enum ReservationStates {RESERVED, CONFIRMED, REJECTED, OVER}

    /** Structure of a reservation. */
    struct Reservation {

        uint256 id;
        uint256 houseId;

        /* Reservation info */
        bytes32 reservationCode;
        address host;
        address reserver;
        address[] guests;

        uint256 checkIn; /* Milliseconds since unix epoch */
        uint256 checkOut;

        /* Logistics */
        ReservationStates state;
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

        require(checkIn <= checkOut);
            
        success = false;
        newId = 0;

        /* Smallest houseId is 1 */
        reservationId += 1;

        Reservation memory reservation;

        /* Fetch house information and check if house is available. */
        var (succ1, fetchedId, , host, active) = houses.getHouseInfo(houseId);
        bool available = checkHouseAvailability(houseId, checkIn, checkOut);

        if (!available || !succ1 || !active || (fetchedId != houseId)) {
            reservationId -= 1;
            return;
        }

        /* Store reservation information. */
        reservation.id = reservationId;
        reservation.houseId = houseId;
        reservation.reserver = msg.sender;
        reservation.checkIn = checkIn;
        reservation.checkOut = checkOut;
        
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

        /* Logistics */
        reservation.state = ReservationStates.RESERVED;

        /* Save newly created house to storage. */
        reservations[reservation.id] = reservation;
        reservationCodes[reservationCode] = reservation.id;
        reservationsBy[msg.sender].push(reservation.id); 
        reservationsAt[houseId].push(reservation.id);

        /* Add host as guest as well */
        reservations[reservation.id].guests.push(msg.sender);

        newId = reservation.id;
        success = true;
    }

    /**
     * Check if house is available for rent.
     *
     * @param houseId Id of the house to check.
     * @param checkIn Time of check in, in milliseconds since UNIX epoch.
     * @param checkOut Time of check out, in milliseconds since UNIX epoch.
     * @return available Whether the house is available during the specified time window.
     */
    function checkHouseAvailability(uint256 houseId, uint256 checkIn, uint256 checkOut) 
        internal view returns (bool available) {

        available = false;

        uint256[] storage reservationIds = reservationsAt[houseId];

        for (uint256 i=0; i < reservationIds.length; i++) {
            Reservation storage reservation = reservations[reservationIds[i]];

            /* Look for overlap. */
            bool checkInTooEarly = (reservation.checkIn <= checkIn) &&
                                   (checkIn <= reservation.checkOut + 1 days);
            bool checkOutTooLate = (reservation.checkIn - 1 days <= checkOut) &&
                                   (checkOut <= reservation.checkOut);

            if (checkInTooEarly || checkOutTooLate) {
                return;
            }
        }
        
        /* Only assign available to true if we found no overlap. */
        available = true;
    }

    /**
     * Generate a unique code for a reservation that acts as an invite.
     *
     * @param host The first seed to randomize reservation code.
     * @param guest The second seed to randomize reservation code.
     * @param id The third seed to randomize reservation code.
     * @return success Whether the reservation was successful.
     * @return reservationCode Randomly generated reservation code.
     */
    function generateReservationCode(address host, address guest, uint256 id) 
        internal pure returns (bool success, bytes32 reservationCode) {

        success = false;

        reservationCode = keccak256(host, guest, id);

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
     * @return state State of the reservation.
     */
    function getReservationInfo(uint256 _id) public view onlyGuests(_id)
        returns (bool success, uint256 id, bytes32 reservationCode, 
                 address host, address reserver, 
                 uint256 checkIn, uint256 checkOut, ReservationStates state) {

        success = false;

        Reservation storage reservation = reservations[_id]; 

        id = reservation.id;
        reservationCode = reservation.reservationCode;
        host = reservation.host;
        reserver = reservation.reserver;
        checkIn = reservation.checkIn;
        checkOut = reservation.checkOut;
        state = reservation.state;

        success = true;
    } 

    /**
     * Guest commits to the reservation. 
     *
     * @param id Id of the reservation.
     * @param valid Whether the guest will go through with the reservation.
     * @return success Whether the operation was successful.
     */
    function confirmReservation(uint256 id, bool valid) public onlyGuests(id) 
        returns (bool success) {

        success = false;

        Reservation storage reservation = reservations[id];

        bool withinTimeFrame = now <= (reservation.checkIn + 1 days);

        if (withinTimeFrame) {
            if (valid) {
                reservation.state = ReservationStates.CONFIRMED;
                // Release funds from escrow to host!
            } else {
                reservation.state = ReservationStates.REJECTED;
                // Refund!
            }
            success = true;
        }
    } 

    /**
     * Fetch reservation information.
     *
     * @param reservationCode Randomly generated reservation code.
     * @return success Whether the operation was successful.
     * @return id Id of the reservation.
     */
    function registerAsGuest(bytes32 reservationCode) public 
        returns (bool success, uint256 id) {

        success = false;

        uint256 resId = reservationCodes[reservationCode];
        Reservation storage reservation = reservations[resId]; 

        bool correctCode = (reservation.reservationCode == reservationCode);
        bool correctState = (reservation.state == ReservationStates.RESERVED) ||
                            (reservation.state == ReservationStates.CONFIRMED);
        bool found;

        /* Search for guest in already registered guest list */
        address[] storage guests = reservation.guests;
        for (uint256 i=0; i < guests.length; i++) {
            if (guests[i] == msg.sender) {
                found = true;
            }
        }

        if (correctCode && correctState && !found) {
            reservation.guests.push(msg.sender);
            reservationsBy[msg.sender].push(reservation.id);
            id = reservation.id;
            success = true;
        }
    } 

    /**
     * Self destruct.
     */
    function kill() system public { 
        selfdestruct(admin); 
    }

}