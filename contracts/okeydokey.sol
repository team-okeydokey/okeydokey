pragma solidity ^0.4.19;

contract OkeyDokey {

    /** Admin of this contract. */
    address private admin;

    /** Running count of contracts in the OkeyDokey ecosystem. */
    uint16 private contractCount = 0;

    /** Address of contracts. 
     * 
     * 0 - OkeyDokeyToken.
     * 1 - Houses.
     * 2 - Devices.
     * 3 - Reservations.
     * 4 - Reviews.
     *
     */
    mapping (uint16 => address) private addresses;

    /**
     * Constrctor function.
     *
     * Set the admin.
     */
    function OkeyDokey() public {
        admin = msg.sender;
    }

    /**
     * Transfer ownership of contract.
     *
     * @param newAdmin The address of the potential new admin.
     * @return success True if transfer of ownership was successful.
     */
    function transferOwnership(address newAdmin) public returns (bool success) {
        require(newAdmin != 0x0);
        require(msg.sender == admin);

        success = false;

        admin = newAdmin;
        
        success = true;
    }

    /**
     * Return address of contracts.
     *
     * @param tag The identifying tag of the contract.
     * @return contractAddr Address of contract with tag.
     */
    function getAddress(uint16 tag) public view returns (address contractAddr) {
        contractAddr = addresses[tag];
    }

    /**
     * Update address of contracts.
     *
     * @param tag The identifying tag of the new contract.
     * @param newAddress The address of the new contract.
     * @return success True if update of address was successful.
     */
    function updateAddress(uint16 tag, address newAddress) public returns (bool success) {
        require(msg.sender == admin);
        require(newAddress != 0x0);

        success = false;

        if (addresses[tag] == 0x0) {
            /* New contract. */
            contractCount += 1;
        }

        addresses[tag] = newAddress;
        
        success = true;
    }

    /**
     * Find out if address is a registered OkeyDokey contract
     *
     * @param addr The address to check.
     * @return valid If the address is a registered OkeyDokey contract.
     */
    function isOkeyDokeyContract(address addr) public view returns (bool valid) {
        require(addr != 0x0);

        valid = false;

        for (uint16 i=0; i < contractCount; i++) {
            if (addresses[i] == addr) {
                valid = true;
                return;
            }
        }
    }

    /**
     * Self destruct.
     */
    function kill() public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}