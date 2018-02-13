pragma solidity ^0.4.19;

contract OkeyDokey {
    /** Get addresses of other contracts. */
    function getAddress(uint16) public view returns (address);
}

contract Devices {
    // function getAddress(uint16) public view returns (address);
}

contract Houses {

    /** Admin of this contract. */
    address private admin;

    /** Running count of house ids. Smallest valid house index is 1. */
    uint256 houseId = 0;

    /** Map of house ids to each corresponding house. */
    mapping(uint256 => House) private houses;

    /** Map of addresses to ids of houses it owns. */
    mapping(address => uint256[]) private housesOf;

    /** Map of a grid's id to houses located in that particular grid. */
    mapping(uint256 => uint256[]) private housesInGrid;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Address of Devices contract. */
    address private devicesAddress;

    /** Instance of Devices contract. */
    Devices private devices;

    /** Structure of a house. */
    struct House {

        /* House info */
        uint256 id;
        bytes ipfsHash;

        /* Owner info */
        address host;
        address[] administrators;

        /* Smart devices */
        address[] devices;

        /* Location */
        uint256 latitude;
        uint256 longitude;

        /* Logistics */
        bool active;
        bool valid;
    }

    /**
     * Modifier for functions only smart contract owner can run.
     */
    modifier system() {
        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house host(owner) can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyHost(uint256 id) {
        House memory house = houses[id]; 

        require(house.valid);  

        /* Verify owner. */
        require(house.host == msg.sender);

        _;
    }

    /**
     * Modifier for functions only designated admins can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyAdmins(uint256 id) {
        House memory house = houses[id]; 

        require(house.valid);  

        /* Search for admin address. */
        bool found = false;
        address[] memory admins = house.administrators;
        for (uint256 i=0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                found = true;
            }
        }

        require(found);

        _;
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
        devices = Devices(okeyDokeyAddress);

        return true;
    }

    /**
     * Register and list a new house.
     *
     * @param ipfsHash Ipfs identifier of JSON file containing house info.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the registration was successful.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse(bytes ipfsHash, uint256 latitude, uint256 longitude) 
        public returns (bool success, uint256 newId) {

        success = false;
        newId = 0;

        /* Smallest houseId is 1 */
        houseId += 1;

        House memory house; 

        house.id = houseId;
        house.host = msg.sender;

        house.ipfsHash = ipfsHash;

        houses[house.id] = house;

        /* Record grid. */
        bool succ;
        uint256 gridId;
        (succ, gridId) = updateCoordinates(house.id, latitude, longitude);
        if (!succ) {
            /* This listing failed. Reset houseId. */
            houseId -= 1;
            return;
        }

        /* Logistics */
        house.active = true;
        house.valid = true;

        /* Add newly created house to storage. */
        housesOf[msg.sender].push(house.id);

        success = true;
        newId = house.id;
    } 

    /**
     * Edit a listed house.
     *
     * @param id The id of the house to edit.
     * @param ipfsHash Ipfs identifier of JSON file containing house info.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the edit was successful.
     */
    function editHouse(uint256 id, bytes ipfsHash, 
        uint256 latitude, uint256 longitude) onlyAdmins(id) public returns (bool success) {

        success = false;

        House storage house = houses[id]; 

        house.ipfsHash = ipfsHash;

        /* Coordinates */
        bool succ;
        uint256 gridId;
        (succ, gridId) = updateCoordinates(id, latitude, longitude);
        if (!succ) {
            return;
        }
        
        success = true;
    } 

    /**
     * Update coordinates for a house listing. 
     *
     * @param id The id of the house to edit.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the update was successful.
     * @return gridId Id within the Earth's grid.
     */
    function updateCoordinates(uint256 id, uint256 latitude, uint256 longitude) 
        internal returns (bool success, uint256 gridId) {

        success = false;

        /* Check new coordinates. */
        bool succ;
        (succ, gridId) = getGridId(latitude, longitude);
        if (!succ) {
            return;
        }

        /* Fetch previous coordinates. */
        House storage house = houses[id];  

        if (house.valid) { /* This is not a new entry. */

            bool prevSucc;
            uint256 prevGridId;
            (prevSucc, prevGridId) = getGridId(house.latitude, house.longitude);

            /* This there was a previous entry. */
            if (prevSucc) {
                if (prevGridId == gridId) {
                    return;
                } else {
                    /* Erase from previous grid group */
                    removeFromGrid(prevGridId, house.id);
                }
            }
        }

        /* Add house to new grid group. */
        housesInGrid[gridId].push(house.id);

        /* Update location. */
        house.latitude = latitude;
        house.longitude = longitude;

        success = true;
     }

     /**
     * Remove houseId from grid.
     *
     * Helper function for editHouse3. 
     *
     * @param prevGridId The id of the grid to erase from.
     * @param id The id of the house to erase.
     * @return success Whether the deletion was successful.
     */
    function removeFromGrid(uint256 prevGridId, uint256 id) internal returns (bool success) {
        success = false;
        uint256[] storage ids = housesInGrid[prevGridId];
        uint256 toErase;
        for (uint256 i=0; i < ids.length; i++) {
            if (ids[i] == id) {
                toErase = i;
            }
        } 
        delete ids[toErase];
        success = true;
    }

    /**
     * Add administrator to house.
     *
     * @param id Id of house to edit.
     * @param newAdmin The address of new admin.
     * @return success Whether the operation was successful.
     */
    function addAdministrator(uint256 id, address newAdmin) 
        onlyHost(id) public returns (bool success) {

        success = false;

        House storage house = houses[id];

        if (house.valid) {
            bool found = false;
            uint256 index = 0;
            address[] memory admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == newAdmin) {
                    found = true;
                    index = i;
                }
            }

            if (!found) {
                house.administrators.push(newAdmin);
                success = true;
                return;
            }
        }

    }

    /**
     * Remove administrator from house.
     *
     * @param id Id of house to query.
     * @param toDelete The address of admin to delete.
     * @return success Whether the operation was successful.
     */
    function removeAdministrator(uint256 id, address toDelete) 
        onlyHost(id) public returns (bool success) {

        success = false;

        House storage house = houses[id];

        if (house.valid) {

            bool found = false;
            uint256 index = 0;
            address[] memory admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == toDelete) {
                    found = true;
                    index = i;
                }
            }

            if (found) {
                delete admins[index];
                success = true;
                return;
            }
        }
    }

    /**
     * Getter for ipfs hash of house.
     *
     * @param id Id of house to query.
     * @return success Whether the query was successful.
     * @return ipfsHash Ipfs identifier of JSON file containing house info.
     */
    function getIpfsHash(uint256 id) public view returns (bool success, bytes ipfsHash) {
        success = false;

        House memory house = houses[id];
        if (house.valid) {
            success = true;
            ipfsHash = house.ipfsHash;
            return;
        }
    }

    /**
     * Calculate grid id from coordinates.
     *
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the coordinates were valid.
     * @return gridId Id within the Earth's grid.
     */
    function getGridId(uint256 latitude, uint256 longitude) public pure returns (bool success, uint256 gridId) {
        success = false;

        success = true;
        gridId = 0;
    }

    /**
     * Self destruct.
     */
    function kill() system public { 
        selfdestruct(admin); 
    }

}