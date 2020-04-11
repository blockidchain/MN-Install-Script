# MasternodeSetup


### For Ubuntu-16.04
Required:
1. BID Coins for Collateral
2. Local Wallet: https://github.com/blockidchain/blockidcoin/releases
3. VPS with Ubuntu 16.04

VPS Commands:

wget -q https://raw.githubusercontent.com/blockidchain/MN-Install-Script/master/masternode-install.sh <br>
sudo chmod +x masternode-install.sh <br>
./masternode-install.sh

### For Ubuntu-18.04
Required:
1. BID Coins for Collateral
2. Local Wallet: https://github.com/blockidchain/blockidcoin/releases
3. VPS with Ubuntu 18.04

VPS Commands:

wget -q https://raw.githubusercontent.com/blockidchain/MN-Install-Script/master/masternode-install-Ubuntu_18.sh <br>
sudo chmod +x masternode-install-Ubuntu_18.sh <br>
./masternode-install-Ubuntu_18.sh

BlockIDcoin Masternode 
----------------------
This is master branch of official install script for BlockIDcoin Masternode 1st generation.

## Usage
The installation / update will start directly when running following command as **root**:
```bash
source <(curl -s https://raw.githubusercontent.com/velescore/veles-installer/master/masternode.sh)
```

## Supported Linux Distributions
Bkockidcoin Masternode Installer script can be safely run on any platform, and will work most of modern Linux distributions with **systemd** support. We plan to support sysVinit and OpenRC in a future. 

If your system is not supported, running this script has **no** side effects - thanks to extensive dependency checking, it will simply exit with an error message containing hints onto which commands/packages are missing on your system and how to install them.

*Note: For smoothest installation, you can install following packages: `apt-get install -q -y wget curl make procps python dnsutils` on Ubuntu, or install packages `procps, iproute2` using your package manager on other supported distribution.
*

### Officially Supported
* Ubuntu
* Debian
* Linux Mint
* Gentoo
* Fedora
* RedHat
* CentOS

### Experimental
* OpenSUSE
* Arch Linux
