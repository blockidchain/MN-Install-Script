#!/bin/bash
echo "****************************************************************************"
echo "*BLOCKIDCOIN*"                                                                     
echo "*BID-16.04-VERSION-1.0.0-SEPUP*"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "first install ? [y/n]"
read -r DOSETUP
if [ "$DOSETUP" = "y" ]
then
sudo apt-get update
sudo apt -y install software-properties-common
sudo apt -y install unzip
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw fail2ban pkg-config libevent-dev libzmq5
echo && echo && echo
sudo wget https://github.com/blockidchain/blockidcoin/releases/download/V1.0.0/blockidcoin-v1.0.0-ubuntu-16.zip
unzip blockidcoin-v1.0.0-ubuntu-16.zip
sleep 10
chmod +x *
fi
## Setup conf
read -p "ServerIP:" ServerIP
echo IP ist:  "$ServerIP"
mkdir .blockidcoin
cd .blockidcoin || exit
echo Configure your masternodes now!
echo "Enter masternode private key for node $ALIAS"
read PRIVKEY
echo "key $COINKEY"
CONF_DIR=~/.blockidcoin
mkdir -p .blockidcoin
echo "rpcuser=user"$(shuf -i 100000-10000000 -n 1) >> blockidcoin.conf
echo "rpcpassword=pass"$(shuf -i 100000-10000000 -n 1) >> blockidcoin.conf
echo "rpcallowip=127.0.0.1" >> blockidcoin.conf
echo "rpcport=54173" >> blockidcoin.conf
echo "listen=1" >> blockidcoin.conf
echo "server=1" >> blockidcoin.conf
echo "daemon=1" >> blockidcoin.conf
echo "bind=$ServerIP" >> blockidcoin.conf
echo "externalip=$ServerIP" >> blockidcoin.conf
echo "maxconnections=256" >> blockidcoin.conf
echo "masternode=1" >> blockidcoin.conf
echo "port=54172" >> blockidcoin.conf
echo "masternodeaddr=$ServerIP:45328" >> blockidcoin.conf
echo "masternodeprivkey=$PRIVKEY" >> blockidcoin.conf
mv sap.conf $CONF_DIR/blockidcoin.conf
echo  -e  "$(crontab -l)\n */2 * * * * ./blockidcoind -datadir=/root/.blockidcoin -config=/root/.blockidcoin/blockidcoin.conf -daemon >/dev/null 2>&1" | crontab -
./blockidcoind
echo finish