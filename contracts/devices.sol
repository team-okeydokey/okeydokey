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

    /** Map of house id to its device addresses */
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
        address owner;
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
     * Modifier to verify that device (caller) is registered to this contract.
     */
    modifier isRegistered(address addr) {

        require(devices[addr].addr != 0);

        _;
    }


    /**
     * Modifier to verify that device (caller) belongs to a house.
     * Premise: isRegistered() returns true.
     */
    modifier belongsToHouse(address addr) {
        
        require(devices[addr].houseId != 0);

        _;
    }
    

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
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
     * Register device (caller) to this contract.
     *
     * @param owner The address of the device owner. 
     * @param deviceType The type of device defined by okdk system. 
     * @param name The name of device.
     * @return success Whether the registration was successful.
     */
    function register(address owner, uint256 deviceType, bytes32 name) public 
        returns (bool success) {

        require(owner != 0);

        Device memory device;
        
        device.addr = msg.sender;
        device.owner = owner; 

        device.deviceType = deviceType; 
        device.name = name; 

        devices[msg.sender] = device;

        success = true; 

    }


    /**
     * De-register device from this contract.
     * ** caller must be the owner of the device.
     *
     * @param deviceAddr The address of device to de-register. 
     * @return success Whether the registration was successful.
     */
    function deRegister(address deviceAddr) isRegistered(deviceAddr) public 
        returns (bool success) {

        success = false; 

        // check if caller is the owner of the device
        require(devices[deviceAddr].owner == msg.sender);

        // if the device belongs to a house, remove from house first
        if(devices[deviceAddr].houseId != 0) {
            this.removeFromHouse(devices[deviceAddr].houseId, deviceAddr);
        }

        // remove device from the list
        //TODO: need to test what this leaves after. 
        delete devices[deviceAddr];

        success = true; 

    }



    /**
     * Add device to a house.
     *
     * @param houseId The address of the device owner. 
     * @param deviceAddr The address of the device owner. 
     * @return success Whether the operation was successful.
     */
    function addToHouse(uint256 houseId, address deviceAddr) isRegistered(deviceAddr) 
        public returns (bool success) {

        success = false;
        
        var (,,,host,) = houses.getHouseInfo(houseId);

        // verify caller is the host of the house
        require(msg.sender == host);

        devices[deviceAddr].houseId = houseId; 
        devicesOf[houseId].push(deviceAddr);

        success = true; 

    }


    /**
     * Remove device from a house.
     *
     * @param houseId The id of the house.
     * @param deviceAddr The address of the device to remove.
     * @return success Whether the operation was successful.
     */
    function removeFromHouse(uint256 houseId, address deviceAddr) belongsToHouse(deviceAddr) 
        public returns (bool success) {

        success = false;
        
        var (,,,host,) = houses.getHouseInfo(houseId);

        // verify caller is the host of the house
        require(msg.sender == host);

        devices[deviceAddr].houseId = 0; 
        
        address[] storage houseDevices = devicesOf[houseId];
        bool found = false;
        uint256 index = 0;

        for (uint256 i = 0; i < houseDevices.length; i++) {
            if (houseDevices[i] == deviceAddr) {
                found = true;
                index = i;
            }
        }

        if (found) {
            // TODO: currently, this leaves a gap (deleting simply makes element 0)
            delete houseDevices[index];
            success = true;
        }
        
    }


    /**
     * Edit device info (device type & name)
     *
     * @param deviceAddr The address of device to register.
     * @param deviceType The type of device defined by okdk system. 
     * @param name The name of device.
     * @return success Whether the edit was successful.
     */
    function editDevice(address deviceAddr, uint256 deviceType, bytes32 name) 
        belongsToHouse(deviceAddr) public returns (bool success) {

        success = false;
        
        var (,,,host,) = houses.getHouseInfo(devices[deviceAddr].houseId);

        // verify caller is the host of the house
        require(msg.sender == host);

        Device storage device = devices[deviceAddr]; 

        if(device.deviceType != deviceType) {
            device.deviceType = deviceType;
        }

        if(device.name != name) {
            device.name = name; 
        }
        
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
    function getDeviceInfo(address addr) isRegistered(addr) public view
        returns (bool success, address deviceAddr, uint256 houseId, 
                uint256 deviceType, bytes32 name, uint256 state) {
    
        success = false;

        Device storage device = devices[addr]; 

        deviceAddr = device.addr;

        // if device doesn't belong to any house, houseId will be 0 
        houseId = device.houseId;

        deviceType = device.deviceType;
        name = device.name; 
        state = uint256(device.state);

        success = true;
    } 
    
    
    /**
     * Verify the guest.
     *
     * @param guest The guest who is trying to activate the device. 
     * @return success Whether the activation was successful.
     */
    function verifyGuest(address guest) belongsToHouse(msg.sender) public view returns (bool success) {
        
        success = false;

        // check if guest is indeed authorized guest for the device's house 
        if(reservations.isCurrentGuest(devices[msg.sender].houseId, guest)) {
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