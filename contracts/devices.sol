pragma solidity ^0.4.19;

contract Devices {

	/**
     * Reinitialize values dependant on other functions.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the reinitialization was successful.
     */
    // function initializeContracts(address _okeyDokeyAddress) public returns (bool success) {
    //     require(msg.sender == admin);
    //     require(_okeyDokeyAddress != 0);
    //     require(_okeyDokeyAddress != address(this));

    //     okeyDokeyAddress = _okeyDokeyAddress;
    //     okeyDokey = OkeyDokey(okeyDokeyAddress);

    //     // devicesAddress = okeyDokey.getAddress(2);
    //     // devices = Devices(devicesAddress);

    //     // reservationsAddress = okeyDokey.getAddress(3);
    //     // reservations = Reservations(reservationsAddress);

    //     // require(devicesAddress != 0x0);
    //     // require(devicesAddress != address(this));

    //     // require(reservationsAddress != 0x0);
    //     // require(reservationsAddress != address(this));

    //     return true;
    // }

}
