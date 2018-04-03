# OkeyDokey
"Opening doors to smart asset utilization."​

OkeyDokey is blockchain and IoT based access control system that integrates digital payment transactions with access to physical doors. 

OkeyDokey’s vision is to drive productivity in cities by providing easy accessibility and cost effective way for people to utilize idling assets. Our mission is to provide blockchain based digital payment transaction integrated smart connected door lock system, which automatically grants access to accommodations, offices and storage spaces to those who’ve paid and been verified by the blockchain network. OkeyDokey drives productivity by relieving the complexities and costs involved in both digital and physical operations of sharing economy.

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
