pragma solidity ^0.4.19;

contract OkeyDokey {
    /** Get addresses of other contracts. */
    function getAddress(uint16) public view returns (address);
}


contract Devices {

}

contract Reservations {

}

contract Houses {

	/** Admin of this contract. */
    address private admin;

    /** Map of house ids to each corresponding house. */
    mapping(uint256 => House) private houses;

    /** Map of addresses to ids of houses it owns. */
    mapping(address => uint256[]) private housesOf;

    /** Map of a grid's id to houses located in that particular grid. */
    mapping(address => uint256[]) private housesIn;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of Devices contract. */
    OkeyDokey private okeyDokey;

    /** Address of Devices contract. */
    address private devicesAddress;

    /** Instance of Devices contract. */
    Devices private devices;

    /** Address of Reservations contract. */
    address private reservationsAddress;

    /** Instance of Reservations contract. */
    Reservations private reservations;

    /** Structure of a house. */
    struct House {

    }

    /**
     * Constrctor function.
     *
     * Assign owner.
     *
     */
    function Houses() public {
        admin = msg.sender;
    }

    /**
     * Reinitialize values dependant on other functions.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the reinitialization was successful.
     */
    function initializeContracts(address _okeyDokeyAddress) public returns (bool success) {
        require(msg.sender == admin);
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        devicesAddress = okeyDokey.getAddress(2);
        devices = Devices(devicesAddress);

        reservationsAddress = okeyDokey.getAddress(3);
        reservations = Reservations(reservationsAddress);

        require(devicesAddress != 0x0);
        require(devicesAddress != address(this));

        require(reservationsAddress != 0x0);
        require(reservationsAddress != address(this));

        return true;
    }

    /**
     * Self destruct.
     */
    function kill() public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}