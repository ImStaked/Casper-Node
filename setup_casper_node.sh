#!/bin/bash

CASPER_VERSION=1_0_0
CASPER_NETWORK=casper

sudo apt-get update -qq
sudo apt install dnsutils software-properties-common git jq libssl-dev pkg-config build-essential -yq
sudo snap install rustup --classic

sudo systemctl stop casper-node-launcher.service
sudo apt remove casper-client casper-node-launcher -yq
sudo rm /etc/casper/casper-node-launcher-state.toml
sudo rm -rf /etc/casper/1_0_*
sudo rm -rf /var/lib/casper/*
sudo apt purge --auto-remove cmake -yq
echo "deb https://repo.casperlabs.io/releases" bionic main | sudo tee /etc/apt/sources.list.d/casper.list
curl -O https://repo.casperlabs.io/casper-repo-pubkey.asc
sudo apt-key add casper-repo-pubkey.asc 
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && sudo apt-key add casper-repo-pubkey.asc
sudo apt update && sudo apt install casper-node-launcher casper-client cmake -yq
cd ~

BRANCH="1.0.20" \
    && git clone --branch ${BRANCH} https://github.com/WebAssembly/wabt.git "wabt-${BRANCH}" \
    && cd "wabt-${BRANCH}" \
    && git submodule update --init \
    && cd - \
    && cmake -S "wabt-${BRANCH}" -B "wabt-${BRANCH}/build" \
    && cmake --build "wabt-${BRANCH}/build" --parallel 8 \
    && sudo cmake --install "wabt-${BRANCH}/build" --prefix /usr --strip -v \
    && rm -rf "wabt-${BRANCH}"
cd ~

git clone git://github.com/CasperLabs/casper-node.git
cd casper-node/
git checkout release-1.4.1
make setup-rs
make build-client-contracts -j



echo "end of autosetup manually finish config"
sleep 6000

sudo -u casper /etc/casper/pull_casper_node_version.sh $CASPER_NETWORK.conf $CASPER_VERSION
KNOWN_ADDRESSES=$(sudo -u casper cat /etc/casper/$CASPER_VERSION/config.toml | grep known_addresses)
KNOWN_VALIDATOR_IPS=$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$KNOWN_ADDRESSES")
IFS=' ' read -r KNOWN_VALIDATOR_IP _REST <<< "$KNOWN_VALIDATOR_IPS"
echo $KNOWN_VALIDATOR_IP


#TRUSTED_HASH=$(casper-client get-block --node-address http://$KNOWN_VALIDATOR_IP:7777 -b 20 | jq -r .result.block.hash | tr -d '\n')
# if [ "$TRUSTED_HASH" != "null" ]; then sudo -u casper sed -i "/trusted_hash =/c\trusted_hash = '$TRUSTED_HASH'" /etc/casper/$CASPER_VERSION/config.toml; fi
# https://cspr.live/block/  <---- Sometimes the known validator does not respond its not your node....

TRUSTED_HASH=6214f009fabbbd601307ab94229d1cf53fcb988f59884e68ab22645ad867dc69

echo "  **** Stop. Manually Configure from here please hit cntl+c then follow the instructions below  ****"
# Set up keys 
sudo -u casper nano  > /etc/casper/validator_keys/secret_key.pem
sudo -u casper nano > /etc/casper/validator_keys/public_key_hex
sudo -u casper nano  > /etc/casper/validator_keys/public_key.pem


sudo -u casper /etc/casper/pull_casper_node_version.sh $CASPER_NETWORK.conf $CASPER_VERSION
# Enter Custom Settings Now
nano /etc/casper/1_0_0/config-example.toml
sudo -u casper /etc/casper/config_from_example.sh $CASPER_VERSION

sudo -u casper sed -i "/trusted_hash =/c\trusted_hash = '$TRUSTED_HASH'" /etc/casper/$CASPER_VERSION/config.toml
sudo -u casper curl -sSf genesis.casperlabs.io/casper/1_1_0/stage_1_1_0_upgrade.sh | sudo bash
sudo -u casper curl -sSf genesis.casperlabs.io/casper/1_1_2/stage_upgrade.sh | sudo bash -
sudo -u casper curl -sSf genesis.casperlabs.io/casper/1_2_0/stage_upgrade.sh | sudo bash -
sudo -u casper curl -sSf genesis.casperlabs.io/casper/1_2_1/stage_upgrade.sh | sudo bash -
sudo -u casper cd ~; curl -sSf genesis.casperlabs.io/casper/1_3_2/stage_upgrade.sh | sudo bash -
sudo -u casper cd ~; curl -sSf genesis.casperlabs.io/casper/1_3_4/stage_upgrade.sh | sudo bash -
sudo -u casper cd ~; curl -sSf genesis.casperlabs.io/casper/1_4_1/stage_upgrade.sh | sudo bash -
