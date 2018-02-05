pragma solidity ^0.4.19;

contract OkeyDokeyGod {

	/** Admin of address. */
    address private admin;

	/** Entry point to application. */
    address private okeyDokeyAddress;

    /**
     * Constrctor function.
     *
     * Assign admin.
     */
    function OkeyDokeyGod() public {
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
        admin = newAdmin;
        return true;
    }

    /**
     * Return entry address to OkeyDokey.
     *
     * @return okeydokeyAddr Address of OkeyDokey.
     */
    function getAddress() public view returns (address okeydokeyAddr){
        okeyDokeyAddr = okeyDokeyAddress;
        return okeyDokeyAddr;
    }

    /**
     * Update entry address to OkeyDokey.
     *
     * @param newAddress The address of the new contract.
     * @return success True if transfer of ownership was successful.
     */
    function updateAddress(address newAddress) public returns (bool success) {
        require(newAddress != 0x0);
        require(newAddress != okeyDokeyAddress);
        require(msg.sender == admin);
    	okeyDokeyAddress = newAddress;
        return true;
    }

    /**
     * Self destruct.
     */
    function kill() public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}