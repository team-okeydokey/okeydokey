# OkeyDokey
OkeyDokey is a blockchain based door opening solutions platform designed for security and flexibility.

### OkeyDokey's Unique Value
OkeyDokey's unique value lies in blockchain based door opening solutions designed for security and to perform rental transactions. In terms of security, OkeyDokey Platform integrated smart locks and access control devices secured via smart contract and distributed ledger system that is practically impossible to hack. OkeyDokey also provides an ecosystem where smart locks and access control devices are able to perform secured and automated transaction involving digital payments to grant time-based access to guests via smart contracts.

<p align="center">
  <img align="center" src="img/logo.png" width="532" height="184" alt="logo.png"/>
</p>

# Whitepaper
Read our [white paper](https://github.com/team-okeydokey/okeydokey/wiki/OKEYDOKEY-White-Paper).

# KEY Token Supply and Distribution
Learn more about our [Token Generation Event](https://github.com/team-okeydokey/okeydokey/wiki/OKEYDOKEY-Token-Generation-Event).



# Dependancies
Install truffle:
```bash
npm install -g truffle
```

Install ganache(Truffle's version of TestRPC):
```bash
npm install -g ganache-cli
```


# Usage
To build and deploy on local ganache test network:
```bash
chmod +x ./build.sh
./build.sh
```

If you encounter `The contract code couldn't be stored, please check your gas amount`, just run `./build.sh` again. This error occurs because we can't deploy abstract contracts.
