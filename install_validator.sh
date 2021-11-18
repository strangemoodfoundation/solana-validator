#!/bin/bash
#set -x -e

echo "###################### WARNING!!! ######################"
echo "###   This script will bootstrap a validator node    ###"
echo "###   for the Solana Testnet cluster, and connect    ###"
echo "###   it to the monitoring dashboard                 ###"
echo "###   at solana.thevalidators.io                     ###"
echo "########################################################"

install_validator () {

  echo "### Which type of validator you want to set up? ###"
  select cluster in "mainnet-beta" "testnet"; do
      case $cluster in
          mainnet-beta ) inventory="mainnet.yaml"; break;;
          testnet ) inventory="testnet.yaml"; break;;
      esac
  done

  echo "Please enter a name for your validator node: "
  read VALIDATOR_NAME
  read -e -p "Please enter the full path to your validator key pair file: " -i "/root/" PATH_TO_VALIDATOR_KEYS

  if [ ! -f "$PATH_TO_VALIDATOR_KEYS/validator-keypair.json" ]
  then
    echo "key $PATH_TO_VALIDATOR_KEYS/validator-keypair.json not found. Pleas verify and run the script again"
    exit
  fi

  read -e -p "Enter new RAM drive size, GB (recommended size: server RAM minus 16GB):" -i "48" RAM_DISK_SIZE
  read -e -p "Enter new server swap size, GB (recommended size: equal to server RAM): " -i "64" SWAP_SIZE

  rm -rf sv_manager/

  if [[ $(which apt | wc -l) -gt 0 ]]
  then
  pkg_manager=apt
  elif [[ $(which yum | wc -l) -gt 0 ]]
  then
  pkg_manager=yum
  fi

  echo "Updating packages..."
  $pkg_manager update
  echo "Installing ansible, curl, unzip..."
  $pkg_manager install ansible curl unzip --yes

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general

  echo "Downloading Solana validator manager version $1"
  cmd="https://github.com/mfactory-lab/sv-manager/archive/refs/tags/$1.zip"
  echo "starting $cmd"
  curl -fsSL "$cmd" --output sv_manager.zip
  echo "Unpacking"
  unzip ./sv_manager.zip -d .

  mv sv-manager* sv_manager
  rm ./sv_manager.zip
  cd ./sv_manager || exit
  cp -r ./inventory_example ./inventory

  # shellcheck disable=SC2154
  echo "pwd: $(pwd)"
  ls -lah ./

  ansible-playbook --connection=local --inventory ./inventory/$inventory --limit localhost  playbooks/pb_config.yaml --extra-vars "{ \
  'validator_name':'$VALIDATOR_NAME', \
  'local_secrets_path': '$PATH_TO_VALIDATOR_KEYS', \
  'swap_file_size_gb': $SWAP_SIZE, \
  'ramdisk_size_gb': $RAM_DISK_SIZE, \
  }"

  if [ ! -z $solana_version ]
  then
    SOLANA_VERSION="--extra-vars {'solana_version':$solana_version}"
  fi

  DISABLE_UFW="--extra-vars {'use_firewall':'False'}"

  ansible-playbook --connection=local --inventory ./inventory/$inventory --limit localhost  playbooks/pb_install_validator.yaml --extra-vars "@/etc/sv_manager/sv_manager.conf" $SOLANA_VERSION $DISABLE_UFW
  
  echo "### 'Uninstall ansible ###"

  $pkg_manager remove ansible --yes

  echo "### Check your dashboard: https://solana.thevalidators.io/d/e-8yEOXMwerfwe/solana-monitoring?&var-server=$VALIDATOR_NAME"

}

version=${1:-latest}
solana_version=$2
echo "installing sv manager version $sv_version"
echo "This script will bootstrap a Solana validator node. Proceed?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) install_validator "$version" "$solana_version"; break;;
        No ) echo "Aborting install. No changes will be made."; exit;;
    esac
done