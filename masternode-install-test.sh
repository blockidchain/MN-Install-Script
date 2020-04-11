!/bin/bash
# version 	v1.2.0-rc1
# description:	Installation of an Veles masternode
# website:      https://veles.network
# twitter:      https://twitter.com/mdfkbtc
# author:  Veles Core developers
# licence: GNU/GPL 
##########################################################

# Configuration variables
TEMP_PATH=$(mktemp -d)
USER='blockidcoin'
CONFIG_FILENAME='blockidcoin.conf'
DATADIR_PATH='/home/blockidcoin/.blockidcoin'
COIN_DAEMON='blockidcoind'
COIN_CLI='blockidcoin-cli'
INSTALL_PATH='/usr/local/bin'
COIN_TGZ_URL='https://github.com/blockidchain/blockidcoin/releases/download/1.0.1/blockidcoin-v1.0.1-daemon-linux.tar.gz'
COIN_NAME='Blockidcoin'
COIN_NAME_SHORT='Blockidcoin'
COIN_PORT=31472
RPC_PORT=31473
START_STOP_TIMEOUT=14
START_STOP_RETRY_TIMEOUT=5
KEY_GEN_TIMEOUT=15

# Autodetection
NODEIP=$(curl -s api.ipify.org)
NEED_REINDEX=""

# Constatnts
declare -A APT_PACKAGES
declare -A YUM_PACKAGES
declare -A EMERGE_PACKAGES
declare -A EQUO_PACKAGES
APT_PACKAGES=(["ps"]="procps" ["ifconfig"]="net-tools" ["ip"]="iproute2" ["dig"]="dnsutils") # net-tools will once be deprecated on all distros, it's fallback for old systems
YUM_PACKAGES=(["ps"]="procps" ["ip"]="iproute")
EMERGE_PACKAGES=(["ps"]="procps" ["ip"]="iproute2")
EQUO_PACKAGES=(["ps"]="procps" ["ip"]="iproute2")
SCRIPT_VERSION='v1.1.04-dev'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BBLUE='\033[1;34m'
BYELLOW='\033[1;33m'
NC='\033[0m'
ST="${BGREEN} *${NC}"
OK="${BLUE}[ ${NC}${BGREEN}ok${NC}${BLUE} ]${NC}"
ERR="${BLUE}[ ${NC}${BRED}"'!!'"${NC}${BLUE} ]${NC}"

function pok() {
  echo -e "${OK}"
}

function perr() {
  echo -e "${ERR}"
  [[ -n $1 ]] && errline="${1}" || errline="An unknown error has occured"
  echo -e "\n${BRED} ✖ Error: ${RED}${errline}\n\n${BRED}Done: The installation has been terminated.${NC}"
  exit 1
}

function pwarn() {
  echo -e "\n${BYELLOW} ☢ Warning: ${YELLOW}${1}${NC}
                                                                        " # so that next OK or !! gets properly aligned
}

function perr_depend()
{
  errline1="Required command ${YELLOW}${1}${RED} is not installed on your system."

  if [[ -n $HAS_APTGET ]]; then 
    install_cmd="apt-get install "$([[ -n ${APT_PACKAGES[${1}]} ]] && echo "${APT_PACKAGES[${1}]}" || echo "${1}")
  elif [[ -n $HAS_YUM ]]; then
    install_cmd="yum install "$([[ -n ${YUM_PACKAGES[${1}]} ]] && echo "${YUM_PACKAGES[${1}]}" || echo "${1}")
  elif [[ -n $HAS_EMERGE ]]; then
    install_cmd="emerge "$([[ -n ${EMERGE_PACKAGES[${1}]} ]] && echo "${EMERGE_PACKAGES[${1}]}" || echo "${1}")
  elif [[ -n $HAS_EQUO ]]; then
    install_cmd="emerge "$([[ -n ${EQUO_PACKAGES[${1}]} ]] && echo "${EQUO_PACKAGES[${1}]}" || echo "${1}")
  else
    install_cmd=''
  fi

  if [[ -n $install_cmd ]]; then
    errline2="Please install it with command: ${BYELLOW}${install_cmd}"
  else
    errline2="Please install ${BYELLOW}${install_cmd}${RED} using your package manager"
  fi
  errline2=${errline2}"\n${RED}After installing required package please run this script again."

  echo -e "\n${BRED}Error:${RED} ${errline1}\n\n${RED}${errline2}\n\n${BRED}Done: The installation has been terminated.${NC}"
  exit 1
}

function check_dependencies() {
  command -v apt-get >/dev/null 2>&1    && HAS_APTGET=1     || HAS_APTGET=''
  command -v yum >/dev/null 2>&1        && HAS_YUM=1        || HAS_YUM=''
  command -v emerge >/dev/null 2>&1     && HAS_EMERGE=1     || HAS_EMERGE=''
  command -v equo >/dev/null 2>&1       && HAS_EQUO=1       || HAS_EQUO=''
  command -v awk >/dev/null 2>&1        && HAS_AWK=1        || HAS_AWK=''
  command -v sed >/dev/null 2>&1        && HAS_SED=1        || HAS_SED=''
  command -v ifconfig >/dev/null 2>&1   && HAS_IFCONFIG=1   || HAS_IFCONFIG=''
  command -v ip >/dev/null 2>&1         && HAS_IP=1         || HAS_IP=''
  command -v netstat >/dev/null 2>&1    && HAS_NETSTAT=1    || HAS_NETSTAT=''
  command -v basename >/dev/null 2>&1   && HAS_BASENAME=1   || HAS_BASENAME=''
  command -v wget >/dev/null 2>&1       && HAS_WGET=1       || HAS_WGET=''
  command -v curl >/dev/null 2>&1       && HAS_CURL=1       || HAS_CURL=''
  command -v gzip >/dev/null 2>&1       && HAS_GZIP=1       || HAS_GZIP=''
  command -v tar >/dev/null 2>&1        && HAS_TAR=1        || HAS_TAR==''
  command -v useradd -h >/dev/null 2>&1 && HAS_USERADD=1    || HAS_USERADD==''
  command -v systemctl >/dev/null 2>&1  && HAS_SYSTEMCTL==1 || HAS_SYSTEMCTL=''
  command -v dig >/dev/null 2>&1        && HAS_DIG==1       || HAS_DIG=''
}

function assert_common_dependencies() {
  uname -a | grep Linux >/dev/null 2>&1 || perr "Sorry, only Linux kernel is currently supported by this script."
  [[ -n $HAS_SYSTEMCTL ]] || perr "Only distributions with ${BRED}systemd${RED} are currently supported.\n${RED}Please upgrade your init system to systemd or install your masternode manually."
  [[ -n $HAS_WGET ]] || perr_depend wget
  [[ -n $HAS_TAR ]] || perr_depend tar
  [[ -n $HAS_GZIP ]] || perr_depend gzip
}

function assert_install_dependencies() {
  echo -en "${ST}   Checking dependencies ...                                           "
  check_dependencies >/dev/null 2>&1
  assert_common_dependencies
  [[ -n $HAS_CURL ]] || perr_depend "curl"
  [[ -n $HAS_AWK ]] || perr_depend "awk"
  [[ -n $HAS_DIG ]] || [[ -n $HAS_IFCONFIG ]] || [[ -n $HAS_NETSTAT ]] || [[ -n $HAS_IP ]] || perr_depend "dig"
  [[ -n $HAS_USERADD ]] || perr_depend "useradd"
  pok
}

function assert_update_dependencies() {
  echo -en "${ST}   Checking dependencies ...                                           "
  check_dependencies
  assert_common_dependencies
  [[ -n $HAS_BASENAME ]] || [[ -n $HAS_AWK ]] || perr_depend basename
  pok
}

function check_installation() {
  echo -en "\n${ST} Checking whether ${COIN_NAME} is already installed ... "
  #if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] ; then
  if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] ; then
    echo "yes"
    start_update
  else
    echo "no"
    start_installation
  fi
}

function check_ufw() {
  echo -en "${ST}   Checking whether UFW firewall is present ... "
  if [ -f "/sbin/ufw" ] && ufw status | grep -wq 'active'; then 
    echo "yes"
    setup_ufw
  else
    echo "no"
  fi
}

function download_and_copy() {
  echo -en "${ST}   Downloading installation archive ...                                "
  cd $TEMP_PATH >/dev/null 2>&1 || perr "Cannot change to the temporary directory: $TEMP_PATH"
  wget -q $COIN_TGZ_URL || perr "Failed to download installation archive"

  # Extract executables to the temporary directory
  if [[ -n HAS_BASENAME ]]; then
    archive_name=$(basename $COIN_TGZ_URL)
  else
    archive_name=$(echo $COIN_TGZ_URL | awk -F'/' '{print $NF}')  # fallback, has asserted in dependencies
  fi

  tar xvzf $archive_name -C ${TEMP_PATH} >/dev/null 2>&1 || perr "Failed to extract installation archive ${archive_name}"

  # Check whether destination files are already installed
  #if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] && [ -e "${INSTALL_PATH}/${COIN_CLI}" ] \
  #  && [ "$(md5sum ${TEMP_PATH}/${COIN_DAEMON})" == "$(md5sum ${INSTALL_PATH}/${COIN_DAEMON})" ] \
  #  && [ "$(md5sum ${TEMP_PATH}/${COIN_CLI})" == "$(md5sum ${INSTALL_PATH}/${COIN_CLI})" ]; then
  #  echo
  #  print_installed_version
  #  echo -e "\n${BGREEN}Congratulations, you have the latest version of ${COIN_NAME} already installed.\n"
  #fi
  
  # Remove if destination files already exist
  if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ]; then
    rm "${INSTALL_PATH}/${COIN_DAEMON}" || perr "Failed to remove old version of ${COIN_DAEMON}"
  fi
  if [ -e "${INSTALL_PATH}/${COIN_CLI}" ]; then
    rm "${INSTALL_PATH}/${COIN_CLI}" || perr "Failed to remove old version of ${COIN_CLI}"
  fi

  # Copy the files to installation directory and ensure executable flags
  cp "${TEMP_PATH}/veles-linux-amd64/${COIN_DAEMON}" "${INSTALL_PATH}/${COIN_DAEMON}" || "Failed to copy ${COIN_DAEMON} to ${INSTALL_PATH}"
  cp "${TEMP_PATH}/veles-linux-amd64/${COIN_CLI}" "${INSTALL_PATH}/${COIN_CLI}" || "Failed to copy ${COIN_CLI} to ${INSTALL_PATH}"
  chmod +x "${INSTALL_PATH}/${COIN_DAEMON}" || "Failed to set exacutable flag for ${INSTALL_PATH}/${COIN_DAEMON}"
  chmod +x "${INSTALL_PATH}/${COIN_CLI}" || "Failed to set exacutable flag for ${INSTALL_PATH}/${COIN_CLI}"

  pok

  rm -rf $TEMP_PATH >/dev/null 2>&1 || pwarn "Failed to remove temporary directory: ${TEMP_PATH}"
  cd - >/dev/null 2>&1
}

function create_user() {
  echo -e "${ST}   Setting up user account ... "
  # our new mnode unpriv user acc is added
  if id "$USER" >/dev/null 2>&1; then
    pwarn "User account ${BYELLOW}${USER}${NC} already exists."                       
  else
    echo -en "${ST}     Creating new user account ${YELLOW}${USER}${NC} ...                               "
    useradd -m $USER && pok || perr
    # TODO: move to another function
    echo -en "${ST}     Creating new datadir ...                                          "
    su - $USER -c "mkdir ${DATADIR_PATH} >/dev/null 2>&1" || perr	"Failed to create datadir: ${DATADIR_PATH}"
    su - $USER -c "touch ${DATADIR_PATH}/${CONFIG_FILENAME} >/dev/null 2>&1" || perr "Failed to create config file: ${DATADIR_PATH}/${CONFIG_FILENAME}"
    pok
  fi
}

function setup_ufw() {
  echo -en "${ST}     Enabling inbound traffic on TCP port ${BYELLOW}${COIN_PORT}${NC} ...                    "
  ufw allow $COIN_PORT/tcp comment "${COIN_NAME_SHORT} MN port" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw allow ssh comment "SSH" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw limit ssh/tcp >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw default allow outgoing >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw enable >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  pok
}
 
function configure_systemd() {
  echo -en "${ST}   Creating systemd service ${BYELLOW}${COIN_NAME_SHORT}${NC} ...                                  "
  cat << EOF > /etc/systemd/system/${COIN_NAME_SHORT}.service && pok || perr "Failed to create systemd service"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
[Unit]
Description=${COIN_NAME_SHORT} service
After=network.target
[Service]
User=$USER
Group=$USER
Type=forking
#PIDFile=$DATADIR_PATH/${COIN_NAME_SHORT}.pid
ExecStart=${INSTALL_PATH}/${COIN_DAEMON} -daemon -conf=$DATADIR_PATH/$CONFIG_FILENAME -datadir=$DATADIR_PATH
ExecStop=-${INSTALL_PATH}/${COIN_CLI} -conf=$DATADIR_PATH/$CONFIG_FILENAME -datadir=$DATADIR_PATH stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  echo -en "${ST}   Reloading systemctl ...                                             "
  systemctl daemon-reload && pok || perr "Failed to reload systemd daemon [systemctl daemon-reload]"
  echo -en "${ST}   Setting up the service to auto-start on system boot ...             "
  systemctl enable ${COIN_NAME_SHORT}.service >/dev/null 2>&1 && pok || perr "Failed to enable systemd servie ${COIN_NAME_SHORT}.service"
  #u $USER;cd $DATADIR_PATH
}

function start_service() {
  echo -en "${ST}   Starting ${COIN_NAME_SHORT}.service ...                                          "
  systemctl start "${COIN_NAME_SHORT}.service" || tries=${START_STOP_TIMEOUT}
  tries=0

  # Wait until we see the proccess running, or until timeout
  while ! ps aux | grep -v grep | grep "${INSTALL_PATH}/${COIN_DAEMON}" > /dev/null && [ ${tries} -lt ${START_STOP_TIMEOUT} ]; do
    sleep 5
    ((tries++))

    # Try to launch again if waiting for too long
    if (( $tries % $START_STOP_RETRY_TIMEOUT == 0 )); then
      pwarn "Service is starting up longer than usual, retrying ...     "
      systemctl restart "${COIN_NAME_SHORT}.service" > /dev/null
    fi
  done

  if [ ${tries} -eq ${START_STOP_TIMEOUT} ]; then
    perr "Service ${COIN_NAME_SHORT}.service failed to start (timeout), ${COIN_DAEMON} is not running,
${RED}please investigate. You can begin by checking output of following commands as root:
${YELLOW}systemctl start ${COIN_NAME_SHORT}.service
${NC}"$(systemctl start ${COIN_NAME_SHORT}.service)"
${YELLOW}systemctl status ${COIN_NAME_SHORT}.service
${NC}"$(systemctl status ${COIN_NAME_SHORT}.service)"
${YELLOW}cat ${DATADIR_PATH}/debug.log
${NC}"$(cat ${DATADIR_PATH}/debug.log | tail -n 10)"
...
"
  else
    pok
  fi
}

function stop_service() {
  echo -en "${ST}   Stopping ${COIN_NAME_SHORT}.service ...                                          "
  systemctl stop "${COIN_NAME_SHORT}.service" || perr "Service ${COIN_NAME_SHORT} failed to stop."
  tries=0

  # Wait until we NOT see the proccess running, or until timeout
  while ps aux | grep -v grep | grep "${INSTALL_PATH}/${COIN_DAEMON}" > /dev/null && [ ${tries} -lt ${START_STOP_TIMEOUT} ]; do
    sleep 1
    ((tries++))
  done

  if [ ${tries} -eq ${START_STOP_TIMEOUT} ]; then
    perr "Service ${COIN_NAME_SHORT} failed to stop."
  else
    pok
  fi
}

function enable_reindex_next_start() {
  # reindex after update
  echo -en "${ST}   Scheduling database reindex on next start ...                       "
  sed -i.bak "s/-daemon -conf/-daemon -reindex -conf/g" "/etc/systemd/system/${COIN_NAME_SHORT}.service" || "Failed to update systemd service configuration"
  systemctl daemon-reload && pok || "Failed to reload systemd daemon"
}

function disable_reindex_next_start() {
  sed -i.bak "s/-daemon -reindex -conf/-daemon -conf/g" "/etc/systemd/system/${COIN_NAME_SHORT}.service" || "Failed to update systemd service configuration"
  systemctl daemon-reload || "Failed to reload systemd daemon"
}


function create_config() {
  echo -en "${ST}   Generating configuration file ...                                   "
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to write configuration to: $DATADIR_PATH/$CONFIG_FILENAME"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
## In case of unavailability of hardcoded seeds
addnode=91.227.43.41
addnode=45.86.68.137
addnode=51.75.73.45
addnode=81.2.239.169
addnode=80.211.86.93
EOF
}

function create_key() {
  if ! [ $ARG1 == '--nonint' ]; then # skip reading in non-interactive mode
    echo -e "Enter your ${RED}${COIN_NAME_SHORT} Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
    read -e COINKEY
  fi
  if [[ -z "$COINKEY" ]]; then
    echo -en "${ST}   Generating masternode private key ...                               "
    ${INSTALL_PATH}/$COIN_DAEMON -daemon >/dev/null 2>&1
    sleep ${KEY_GEN_TIMEOUT}
    if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
      perr "${RED}${COIN_NAME_SHORT} server couldn not start. Check /var/log/syslog for errors.${NC}"
    fi
    COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    if [ "$?" -gt "0" ];then
      echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
      sleep $((KEY_GEN_TIMEOUT * 2))
      COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    fi
    ${INSTALL_PATH}/${COIN_CLI} stop >/dev/null 2>&1
  fi
  pok
}

function update_config() {
  echo -en "${ST}   Updating configuration file ...                                     "
  sed -i 's/daemon=1/daemon=0/' $DATADIR_PATH/$CONFIG_FILENAME
  cat << EOF >> $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to update config file: $DATADIR_PATH/$CONFIG_FILENAME"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
logintimestamps=1
maxconnections=256
txindex=1
listenonion=0
masternode=1
masternodeaddr=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
EOF
  # Might be useful in the future:
  # bind=$NODEIP, externalip=$NODEIP:$COIN_PORT
}

function get_ip() {
  declare -a NODE_IPS
  debug_info=''

  echo -en "${ST}   Obtaining external IP address(es)                                   "

  if [[ -n $HAS_DIG ]]; then
    ifaces=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)
    debug_info="dig @resolver1.opendns.com ANY myip.opendns.com +short: '"$(dig @resolver1.opendns.com ANY myip.opendns.com)"'"
  elif [[ -n $HAS_IP ]]; then
    ifaces=$(ip -o link | awk '!/lo/ {gsub( /\:/, ""); print $2}')
    debug_info="ip -o link: '"$(ip -o link)"'"
  elif [[ -n $HAS_IFCONFIG ]]; then
    ifaces=$(ifconfig -s | awk '!/Kernel|Iface|lo/ {print $1," "}')
    debug_info="ifconfig -s: '"$(ifconfig)"'"
  else # dependencies has been asserted earlier
    ifaces=$(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
    debug_info="netstat -i: '"$(netstat -i)"'"
  fi

  # Check whether we have interface list
  if [[ -n $ifaces ]]; then
    for iface in $ifaces
    do
      # some docker interfaces has @ in them, like eth0@if5, curl needs iface name cleaned up
      NODE_IPS+=($(curl --interface $(echo $iface | awk -F@ '{print $1}') -s api.ipify.org))
    done
  else
    pwarn "Failed to obtain network interface list, using the first available
external IP address"
    NODE_IPS+=($(curl -s api.ipify.org))
  fi

  # Check whether we have more than one IP
  if [ ${#NODE_IPS[@]} -gt 1 ]; then
    if [ $ARG1 == '--nonint' ]; then
      pwarn "More than one IPv4 detected but running in non-interactive mode, \nusing the first one: ${NODE_IPS[0]}"
      NODEIP=${NODE_IPS[0]}
    else
      echo -e "${GREEN}More than one IPv4 detected. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
    fi
  else
    NODEIP=${NODE_IPS[0]}
  fi

  # Make sure we have IP address by now, one more try without interface parameter and throw error
  if ! [[ -n "${NODEIP}" ]]; then
    NODEIP=$(curl -s api.ipify.org)
    if [ ${#NODE_IPS[@]} -gt 1 ] && [[ -n "${NODEIP}" ]]; then
      pwarn "More than one network interface detected but succeeded to obtain only one IPv4: ${NODEIP}"
    fi

    if ! [[ -n "${NODEIP}" ]]; then
      if [ $ARG1 == '--nonint' ]; then
        perr "Failed to detect external IP address and can't ask for it in non-interactive mode\n
  please include following information with your bug report:
  HAS_IP: ${HAS_IP}, HAS_IFCONFIG: ${HAS_IFCONFIG}, HAS_NETSTAT: ${HAS_NETSTAT}, IFACES: ${ifaces}, DEBUG_DUMP:\n'${debug_info}'"
      else
        pwarn "Failed to detect external IP address, please check with whatsmyip.org
  ${YELLOW}or similar service, enter your IP address manually and press Enter:"
        read -n NODEIP
        [[ -n ${NODEIP} ]] || perr "You have not entered your IP adress, please run the script again \nand reenter your IP address."
      fi
    fi
  fi

  pok
}

function print_installed_version() {
  echo -en "${BGREEN}"
  ${INSTALL_PATH}/${COIN_DAEMON} -version | head -n 1
  echo -en "${NC}"
}

function print_logo() {
  echo -e '__________.__                 __   .___________               .__        
\______   \  |   ____   ____ |  | _|   \______ \   ____  ____ |__| ____  
 |    |  _/  |  /  _ \_/ ___\|  |/ /   ||    |  \_/ ___\/  _ \|  |/    \ 
 |    |   \  |_(  <_> )  \___|    <|   ||    `   \  \__(  <_> )  |   |  \
 |______  /____/\____/ \___  >__|_ \___/_______  /\___  >____/|__|___|  /
        \/                 \/     \/           \/     \/              \/ 
   _____                   __                                 .___       
  /     \ _____    _______/  |_  ___________  ____   ____   __| _/____   
 /  \ /  \\__  \  /  ___/\   __\/ __ \_  __ \/    \ /  _ \ / __ |/ __ \  
/    Y    \/ __ \_\___ \  |  | \  ___/|  | \/   |  (  <_> ) /_/ \  ___/  
\____|__  (____  /____  > |__|  \___  >__|  |___|  /\____/\____ |\___  > 
        \/     \/     \/            \/           \/            \/    \/ '
}

function print_install_notice() {
  echo -e "${ST} ${BGREEN}Done.${NC}\n"
  print_installed_version
  echo -e "\n$COIN_NAME Masternode is up and running listening on port ${BYELLOW}$COIN_PORT${NC}."
  echo -e "Configuration file is: ${BYELLOW}$DATADIR_PATH/$CONFIG_FILENAME${NC}"
  echo -e "VPS_IP:PORT ${BYELLOW}$NODEIP:$COIN_PORT${NC}"
  echo -e "MASTERNODE PRIVATEKEY is: ${BYELLOW}$COINKEY${NC}"
  print_usage_notice
}

function print_update_notice() {
  echo -e "${ST} ${BGREEN}Done.${NC}\n"
  print_installed_version
  echo -e "\n$COIN_NAME Masternode is up and running on the latest offical version."
  print_usage_notice
}

function print_usage_notice() {
  echo -e "Start: ${BYELLOW}systemctl start ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Stop: ${BYELLOW}systemctl stop ${COIN_NAME_SHORT}.service${NC}"
  echo -e "You can always check whether ${BYELLOW}${COIN_NAME_SHORT}${NC} daemon is running "
  echo -e "with the following command: ${BYELLOW}systemctl status ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Use ${BYELLOW}${COIN_CLI} masternode status${NC} to check your MN."
  echo -e "For help join discord ${RED}https://discord.gg/P528fGg${NC} ..."
  if [[ -n $SENTINEL_REPO  ]]; then
    echo -e "${BYELLOW}Sentinel${NC} is installed in ${RED}$DATADIR_PATH/sentinel${NC}"
    echo -e "Sentinel logs is: ${BYELLOW}$DATADIR_PATH/sentinel.log${NC}"
  fi
}

function configure_daemon() {
  create_user
  get_ip
  check_ufw
  create_config
  configure_systemd
 }

function install_masternode() {
  create_key
  update_config
 }

function start_installation() {
  echo -en "${ST} Starting ${COIN_NAME} installation..."
  assert_install_dependencies
  download_and_copy
  configure_daemon 
  install_masternode
  start_service
  print_install_notice
  echo -e "\n${BGREEN}Congratulations, ${COIN_NAME} has been installed successfuly.\n"
}

function start_update() {
  echo -e "${ST} Starting ${COIN_NAME} update ..."
  assert_update_dependencies
  stop_service
  download_and_copy
  enable_reindex_next_start
  start_service
  disable_reindex_next_start
  print_update_notice
  echo -e "\n${BGREEN}Congratulations, ${COIN_NAME} has been updated successfuly.\n"
}


##### Main #####
# Load ze args
if ! [ -z "$1" ]; then
  ARG1="${1}"
else
  ARG1=""
fi

if [ "${ARG1}" == "--nonint" ]; then
  echo -e "\n[ $0: Running in non-interactive mode, increasing timeout settings ]"
  # Increase timeouts when in non-interactive mode
  START_STOP_TIMEOUT=$((START_STOP_TIMEOUT * 2))
  START_STOP_RETRY_TIMEOUT=$((START_STOP_RETRY_TIMEOUT * 2))
  KEY_GEN_TIMEOUT=$((KEY_GEN_TIMEOUT * 2))
fi

print_logo
check_installation
