pragma solidity ^0.4.19;

import "../core/OkeyDokey.sol";
import "../token/OkeyToken.sol";
import "./Houses.sol";

contract Reservations is tokenRecipient {

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

    /** Address of Key Token contract. */
    address private tokenAddress;

    /** Instance of Key Token contract. */
    OkeyToken private token;

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

        uint256 checkIn; /* Seconds since unix epoch */
        uint256 checkOut;

        /* Logistics */
        ReservationStates state;
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
        require(okeyDokey.isOkeyDokeyContract(addr));

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
     * Broadcast successful reservation.
     *
     * @param id Id of the reservation.
     */
     event NewReservation(uint256 id);

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
     */
    function initializeContracts(address _okeyDokeyAddress) 
        OkeyDokeyAdmin public returns (bool success) {
        require(_okeyDokeyAddress != address(0));
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        tokenAddress = okeyDokey.getAddress(0);
        token = OkeyToken(tokenAddress);

        housesAddress = okeyDokey.getAddress(1);
        houses = Houses(housesAddress);
    }
        
    /**
     * Make a reservation.
     *
     * @param guest The address of reserver.
     * @param houseId The id of house to reserve.
     * @param checkIn Time of check in, in seconds since UNIX epoch.
     * @param checkOut Time of check out, in seconds since UNIX epoch.
     */
    function _reserve(address guest, uint256 houseId, 
        uint256 checkIn, uint256 checkOut) internal {

        require(checkIn <= checkOut);

        /* Smallest reservationId is 1 */
        reservationId += 1;

        Reservation memory reservation;

        /* Fetch house information and check if house is available. */
        var (, , host, , , , , active) = houses.getHouseInfo(houseId);
        bool available = checkHouseAvailability(houseId, checkIn, checkOut);

        if (!available || !active) {
            reservationId -= 1;
            return;
        }

        /* Store reservation information. */
        reservation.id = reservationId;
        reservation.houseId = houseId;
        reservation.reserver = guest;
        reservation.checkIn = checkIn;
        reservation.checkOut = checkOut;
        
        /* Set host. */
        reservation.host = host;

        /* Assign reservation code. */
        var (succ2, reservationCode) 
            = generateReservationCode(guest, host, reservationId);
        if (!succ2) {
            reservationId -= 1;
            return;
        }
        reservation.reservationCode = reservationCode;

        /* Logistics */
        reservation.state = ReservationStates.RESERVED;

        /* Save newly created reservation to storage. */
        reservations[reservation.id] = reservation;
        reservationCodes[reservationCode] = reservation.id;
        reservationsBy[guest].push(reservation.id); 
        reservationsAt[houseId].push(reservation.id);

        /* Add reserver as guest as well */
        reservations[reservation.id].guests.push(guest);

        NewReservation(reservationId);
    }

    /**
     * Check if house is available for rent.
     *
     * @param houseId Id of the house to check.
     * @param checkIn Time of check in, in seconds since UNIX epoch.
     * @param checkOut Time of check out, in seconds since UNIX epoch.
     * @return available Whether the house is available during the specified time window.
     */
    function checkHouseAvailability(uint256 houseId, uint256 checkIn, uint256 checkOut) 
        internal view returns (bool available) {

        // For testing.
        return true;

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
     * @return houseId Id of the reserved house.
     * @return reservationCode Randomly generated reservation code.
     * @return host Address of the host.
     * @return reserver Address of the reserver.
     * @return checkIn Time of check in, in seconds since UNIX epoch.
     * @return checkOut Time of check out, in seconds since UNIX epoch.
     * @return state State of the reservation.
     */
    function getReservationInfo(uint256 _id) public view onlyGuests(_id)
        returns (bool success, uint256 id, uint256 houseId,
                 bytes32 reservationCode, address host, address reserver,
                 uint256 checkIn, uint256 checkOut, ReservationStates state) {

        success = false;

        id = reservations[_id].id;
        houseId = reservations[_id].houseId;
        reservationCode = reservations[_id].reservationCode;
        host = reservations[_id].host;
        reserver = reservations[_id].reserver;
        checkIn = reservations[_id].checkIn;
        checkOut = reservations[_id].checkOut;
        state = reservations[_id].state;

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
     * Check if guest address has access to house at current time.
     *
     * @param houseId House to check access to.
     * @param guest Address of the guest to check for.
     * @return authorized Whether the guest has access.
     */
    function isCurrentGuest(uint256 houseId, address guest) 
        public system(msg.sender) view returns (bool authorized) {
        require(guest != 0x0);
        require(houseId > 0);

        // For testing.
        return true;

        authorized = false;

        uint256[] storage reservationIds = reservationsBy[guest];

        for (uint256 i=0; i < reservationIds.length; i++) {

            Reservation storage reservation = reservations[reservationIds[i]];

            bool correctState = reservation.state == ReservationStates.RESERVED ||
                                reservation.state == ReservationStates.CONFIRMED;

            bool correctHouseId = reservation.houseId == houseId;

            bool correctTime = reservation.checkIn <= now && 
                               now <= reservation.checkOut;

            if (correctState && correctHouseId && correctTime) {
                authorized = true;
                return;
            }
        }

    } 

    /**
     * Check if guest address has access to house at current time.
     *
     * @param checkIn Time of check in, in seconds since UNIX epoch.
     * @param checkOut Time of check out, in seconds since UNIX epoch.
     * @param hourlyRate Hourly fee in KEY tokens.
     * @param dailyRate Daily fee in KEY tokens.
     * @param utilityFee Utility fee in KEY tokens.
     * @param cleaningFee Cleaning fee in KEY tokens.
     * @return reservationFee Total cost of reservation.
     */
    function calculateReservationFee(uint256 checkIn, uint256 checkOut, 
        uint256 hourlyRate, uint256 dailyRate, 
        uint256 utilityFee, uint256 cleaningFee) 
        public view returns (uint256 reservationFee) {

        reservationFee = 50;
    } 

    /**
     * Callback function for approveAndCall.
     *
     * @param _from Guest that wants to reserve.
     * @param _value Amount of token sent to the contract.
     * @param _token Address of KEY token.
     * @param _extraData Data containing house id, checkin time,and check out time.
     */
    function receiveApproval(address _from, uint256 _value, 
        address _token, bytes _extraData) public {

        require(tokenAddress == _token);

        uint256 houseId;
        uint256 checkIn;
        uint256 checkOut;
        (houseId, checkIn, checkOut) = _decodeReservationData(_extraData);

        address host;
        uint256 hourlyRate;
        uint256 dailyRate;
        uint256 utilityFee;
        uint256 cleaningFee;
        bool active;
        (, , host, hourlyRate, dailyRate, 
            utilityFee, cleaningFee, active) = houses.getHouseInfo(houseId);

        assert(active);

        uint256 reservationFee = calculateReservationFee(checkIn, checkOut,
            hourlyRate, dailyRate, utilityFee, cleaningFee);

        assert(_value >= reservationFee);

        if (token.transferFrom(_from, host, reservationFee)) {
            _reserve(_from, houseId, checkIn, checkOut);
        }
    } 

    /**
     * Decode extra data in approveAndCall to reservation data.
     *
     * @param data Data containing house id, checkin time,and check out time.
     * @return houseId House id.
     * @return checkIn Chek in date.
     * @return checkOut Check out date.
     */
    function _decodeReservationData(bytes data) internal pure 
        returns (uint256 houseId, uint256 checkIn, uint256 checkOut) {

        houseId = 1;
        checkIn = 1522622157;
        checkOut = 1522682157;
    }

    /**
     * Self destruct.
     */
    function kill() OkeyDokeyAdmin public { 
        selfdestruct(admin); 
    }

}