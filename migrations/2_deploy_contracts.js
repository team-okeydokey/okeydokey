var OkeyDokeyGod = artifacts.require("OkeyDokeyGod");
var OkeyDokey = artifacts.require("OkeyDokey");
var Token = artifacts.require("OkeyDokeyToken");
var Houses = artifacts.require("Houses");
var Devices = artifacts.require("Devices");
var Reservations = artifacts.require("Reservations");
var Reviews = artifacts.require("Reviews");

/** Deploy dependancies first.
 *
 * Solution derived from 
 * https://ethereum.stackexchange.com/questions/30572/truffle-post-deployment-actions
 *
 */
module.exports = async function(deployer) {

    let OkeyDokeyGodInst, OkeyDokeyInst, TokenInst;
    let HousesInst, DevicesInst, ReservationsInst, ReviewsInst;

    await Promise.all([
        deployer.deploy(OkeyDokeyGod),
        deployer.deploy(OkeyDokey),
        deployer.deploy(Token, 1000000000, "OkeyDokeyToken", "ODK"),
        deployer.deploy(Devices),
        deployer.deploy(Reservations),
        deployer.deploy(Reviews),
        deployer.deploy(Houses)
    ]).catch(function(error) {
        console.log(error);
    });

    // Wait for deployment to finish.
    instances = await Promise.all([
        OkeyDokeyGod.deployed(),
        OkeyDokey.deployed(),
        Token.deployed(),
        Devices.deployed(),
        Reservations.deployed(),
        Reviews.deployed(),
        Houses.deployed()
    ]).catch(function(error) {
        console.log(error);
    });

    // Assign instances.
    OkeyDokeyGodInst = instances[0];
    OkeyDokeyInst = instances[1];
    TokenInst = instances[2];
    DevicesInst = instances[3];
    ReservationsInst = instances[4];
    ReviewsInst = instances[5];
    HousesInst = instances[6];

    // Set addresses.
    results = await Promise.all([
        OkeyDokeyGodInst.updateAddress(OkeyDokeyInst.address),
        OkeyDokeyInst.updateAddress(0, TokenInst.address),
        OkeyDokeyInst.updateAddress(1, HousesInst.address),
        OkeyDokeyInst.updateAddress(2, DevicesInst.address),
        OkeyDokeyInst.updateAddress(3, ReservationsInst.address),
        OkeyDokeyInst.updateAddress(4, ReviewsInst.address),
        HousesInst.initializeContracts(OkeyDokeyInst.address),
        // DevicesInst.initializeContracts(OkeyDokeyInst.address),
        // ReservationsInst.initializeContracts(OkeyDokeyInst.address),
        // ReviewsInst.initializeContracts(OkeyDokeyInst.address)

        HousesInst.registerHouse("hello", 100, 100)
    ]).catch(function(error) {
        console.log(error);
    });


    // Check initialization.
    const godOkdk = await OkeyDokeyGodInst.getAddress();
    const okdkToken = await OkeyDokeyGodInst.getAddress(0);
    const okdkHouses = await OkeyDokeyInst.getAddress(1);
    const okdkDevices = await OkeyDokeyInst.getAddress(2);
    const okdkReservations = await OkeyDokeyInst.getAddress(3);
    const okdkReviews = await OkeyDokeyInst.getAddress(4);

    var godCheck = (godOkdk == OkeyDokeyInst.address);
    var okeyDokeyCheck1 = (okdkToken == Token.address);
    var okeyDokeyCheck2 = (okdkHouses == HousesInst.address);
    var okeyDokeyCheck3 = (okdkDevices == DevicesInst.address);
    var okeyDokeyCheck4 = (okdkReservations == ReservationsInst.address);
    var okeyDokeyCheck5 = (okdkReviews == ReviewsInst.address);

    printTestResult(godCheck, 'OkeyDokeyGod', 'OkeyDokey');
    printTestResult(okeyDokeyCheck1, 'OkeyDokey', 'Token');
    printTestResult(okeyDokeyCheck2, 'OkeyDokey', 'Houses');
    printTestResult(okeyDokeyCheck3, 'OkeyDokey', 'Devices');
    printTestResult(okeyDokeyCheck4, 'OkeyDokey', 'Reservations');
    printTestResult(okeyDokeyCheck5, 'OkeyDokey', 'Reviews');

    // Print addresses.
    for (var inst of instances) {
        printAddress(inst.constructor._json.contractName, 
                     inst.address);
    }
};

var printTestResult = function(success, parent, child) {
    if (success) {
        console.log('Initialization of ' + child + ' in ' + parent +' successful.');

    } else {
        console.log('Init error! Initialization of ' + child + ' in ' + parent + ' failed.');
    }
}

var printAddress = function(name, address) {
    console.log('Address of ' + name + ' is ' + address +'.');

}