pragma solidity ^0.4.19;

import "./okeydokey.sol";
import "./reservations.sol";
import "./houses.sol";

contract Devices {

    /** Admin of this contract. */
    address private admin;

    // /** Running count of device ids. Smallest valid device index is 1. */
    // uint256 deviceId = 0;

    /** Map of device address to each corresponding device. */
    mapping(address => Device) private devices;

    // houseId => device addrs 
    mapping(uint256 => address[]) private devicesOf;
    

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Address of Reservations contract. */
    address private reservationsAddress;

    /** Instance of Reservations contract. */
    Reservations private reservations;

    /** Address of Reservations contract. */
    address private housesAddress;

    /** Instance of Reservations contract. */
    Houses private houses;

    /** Device states */
    enum DeviceStates {ACTIVE, INACTIVE}

    /** Structure of a device. */
    struct Device {
        // uint256 id;
        address addr;
        uint256 houseId;
        
        uint256 deviceType; // (ex: 0: doorlock, 1: ...)
        bytes32 name; // device name (ex: doorlock_front, doorlock_garage)
        
        DeviceStates state;
    }
    
    event Activate (
        address deviceAddr,
        uint currentTime
    );
    

    /**
     * Modifier for functions only smart contract owner(admin) can run.
     */
    modifier system() {

        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier to verify that device (caller) actually belongs to given house.
     */
    modifier validDevice(address addr) {

        require(devices[addr].addr != addr);

        _;
    }

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
     *
     */
    function Devices() public {
        admin = msg.sender;
    }
    
    /**
     * Initialize other OKDK contracts this contract depends on.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the initialization was successful.
     */
    function initializeContracts(address _okeyDokeyAddress) system public 
        returns (bool success) {
            
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        reservationsAddress = okeyDokey.getAddress(3);
        reservations = Reservations(reservationsAddress);

        return true;
    }



    /**
     * Verify the guest and the reservation before activating device. 
     *
     * @param reservationId The id of reservation.
     * @param guest The guest who is trying to activate the device. 
     * @param currentTime The current time for user (in milliseconds since UNIX epoch).
     * @return success Whether the activation was successful.
     */
    function verifyGuest(uint256 reservationId, address guest, uint256 currentTime) 
        public returns (bool success) {
        
        success = false; 
        
        // check if guest is indeed the guest of the given reservation
        // require(reservations.isGuest(reservationId, guest));

        // TODO: ***** msg.sender is the device, so it won't work with current implementation. 
        var (,, houseId,,, reserver, checkIn, checkOut, rState) = reservations.getReservationInfo(reservationId);

        // check if caller(device) indeed belongs to the house specified in reservation
        require(devices[msg.sender].houseId == houseId);

        // check whether reservation state is CONFIRMED and currentTime is valid 
        require(uint256(rState) == 1); 
        require(checkIn <= currentTime && currentTime <= checkOut);

        success = true;  
    }
    
    /**
     * Register device for a house. 
     *
     * @param houseId The Id of house to register device to. 
     * @param deviceAddr The address of device to register.
     * @param deviceType The type of device defined by okdk system. 
     * @param name The name of device.
     * @return success Whether the registration was successful.
     */
    function registerDevice(uint256 houseId, address deviceAddr, uint256 deviceType, bytes32 name) 
        public returns (bool success) {
        //TODO: must check if given device actually belongs to the house

        success = false;
        
        var (,,,host,) = houses.getHouseInfo(houseId);

        // verify caller is the host of the house
        require(msg.sender == host);
    
        Device memory device;
        
        device.addr = deviceAddr;
        device.houseId = houseId; 

        device.deviceType = deviceType; 
        device.name = name; 
        
        device.state = DeviceStates.ACTIVE;

        devices[deviceAddr] = device;
        
        
        devicesOf[houseId].push(deviceAddr);
    
        success = true; 
    }

    /**
     * Fetch device information.
     *
     * @param addr The address of the device to query.
     * @return success Whether the query was successful.
     * @return deviceAddr The address of the device.
     * @return houseId The Id of the house device belongs to.
     * @return deviceType The type of the device.
     * @return name The name of the device.
     * @return state The state of the device.
     */
    function getDeviceInfo(address addr) validDevice(addr) public view
        returns (bool success, address deviceAddr, uint256 houseId, 
                uint256 deviceType, bytes32 name, uint256 state) {
    
        success = false;

        Device storage device = devices[addr]; 

        deviceAddr = device.addr;
        houseId = device.houseId;

        deviceType = device.deviceType;
        name = device.name; 
        state = uint256(device.state);

        success = true;
    } 

}
