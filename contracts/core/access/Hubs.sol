pragma solidity ^0.4.19;

contract Hubs {

    /** Admin of this contract. */
    address private admin;

    /** Hub address to owner's address. */
    mapping (address => address) private ownerOf;

    /** Hub address to its facility id. */
    mapping (address => bytes32) private facilityOf;

    /** Facility id to list of hubs. */
    mapping (bytes32 => address[]) private hubsIn;

    /** Hub address to its device ids */
    mapping (address => bytes32[]) devicesOf;

    /** Device id to device */
    mapping (bytes32 => Device) private devices;

    /** Definition of a device attached to the hub. */
    struct Device {
        bytes32 id; // Hash of hub address and connected device's mac address.
        bytes32 name;
    }

    /**
     * Constrctor function.
     *
     * Set the admin.
     */
    function Hubs() public {
        admin = msg.sender;
    }

    /**
     * Register a hub to a facility. Called from the hub.
     *
     * @param owner Owner of the hub and facility.
     * @param facilityId Id of the facility this hub belongs in.
     */
    function registerHub(address owner, bytes32 facilityId) {
        ownerOf[msg.sender] = owner;
        facilityOf[msg.sender] = facilityId;
        hubsIn[facilityId].push(msg.sender);
    }

    /**
     * Add a device to a hub.
     *
     * @param hubAddress Address of hub to add the device to.
     * @param macAddress MAC address of device.
     * @param name Name of the device.
     */
    function registerDevice(address hubAddress, bytes macAddress, bytes32 name) {

        require(msg.sender == ownerOf[hubAddress]);

        bytes32 deviceId = sha3(hubAddress, macAddress);

        /* Create new device instance. */
        Device memory device;
        device.id = deviceId;
        device.name = name;

        /* Save to memory. */
        devices[deviceId] = device;
        devicesOf[hubAddress].push(deviceId);
    }

    /**
     * Self destruct.
     */
    function kill() public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}