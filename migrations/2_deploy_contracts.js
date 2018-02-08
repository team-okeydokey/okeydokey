var OkeyDokeyGod = artifacts.require("OkeyDokeyGod");
var OkeyDokey = artifacts.require("OkeyDokey");
var Houses = artifacts.require("Houses");
var Devices = artifacts.require("Devices");
var Reservations = artifacts.require("Reservations");
var Reviews = artifacts.require("Reviews");

module.exports = function(deployer) {
    deployer.deploy(OkeyDokeyGod);
    deployer.deploy(OkeyDokey);
    deployer.deploy(Houses);
    deployer.deploy(Devices);
    deployer.deploy(Reservations);
    deployer.deploy(Reviews);
};
