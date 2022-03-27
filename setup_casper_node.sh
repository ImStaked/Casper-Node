#!/bin/bash



sudo apt-get update -qy
sudo apt-get upgrade -qy
sudo shutdown -r now

sudo apt-get -qq install libssl-dev pkg-config git dnsutil lshw ethtool zip unzip pciutils usbutils netstat-nat software-properties-common jq htop nmon nmap nload iotop net-tools ca-certificates apt-transport-https unattended-upgrades needrestart lm-sensors powermgmt-base dnsutils git jq libssvl-dev pkg-config build-essential bash-completion mlocate htop mlocate dmidecode lm-sensors cpufrequtils nload nmon -yq

echo "deb https://repo.casperlabs.io/releases" bionic main | sudo tee -a /etc/apt/sources.list.d/casper.list
curl -O https://repo.casperlabs.io/casper-repo-pubkey.asc
sudo apt-key add casper-repo-pubkey.asc
sudo apt update
sudo apt install build-essential ca-certificates unattended-upgrades whois needrestart jq gnupg autoconf automake flex bison debian-keyring g++-multilib g++-9-multilib manpages
apt update
apt install casper-node-launcher -yq
apt install casper-client -yq
cd ~
sudo apt purge --auto-remove cmake
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'   
sudo apt update
sudo apt install cmake -yq

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env

BRANCH="1.0.20"     && git clone --branch ${BRANCH} https://github.com/WebAssembly/wabt.git "wabt-${BRANCH}"     && cd "wabt-${BRANCH}"     && git submodule update --init     && cd -     && cmake -S "wabt-${BRANCH}" -B "wabt-${BRANCH}/build"     && cmake --build "wabt-${BRANCH}/build" --parallel 8     && sudo cmake --install "wabt-${BRANCH}/build" --prefix /usr --strip -v     && rm -rf "wabt-${BRANCH}"
cd ~
git clone https://github.com/casper-network/casper-node.git
cd casper-node/
git checkout release-1.4.4
make setup-rs
make build-client-contracts -j

cd /etc/casper/validator_keys/
sudo -u casper touch public_key_hex
sudo -u casper touch public_key.pem
sudo -u casper touch secret_key.pem
echo "public_key" > public_key_hex
echo "public_key_ssl" > public_key.pem
echo "secret" > secret_key.pem 

sudo -u casper /etc/casper/node_util.py stage_protocols casper.conf
sudo sed -i "/trusted_hash =/c\trusted_hash = '$(casper-client get-block --node-address http://3.14.161.135:7777 -b 20 | jq -r .result.block.hash | tr -d '\n')'" /etc/casper/1_0_0/config.toml
sudo /etc/casper/node_util.py rotate_logs
sudo /etc/casper/node_util.py start
/etc/casper/node_util.py watch
sudo -u casper touch secret_key.pem
