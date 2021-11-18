# Running A Solana Validator in AWS

This is a slightly modified script from [mfactory-lab/sv-manager](https://github.com/mfactory-lab/sv-manager).

## AWS Instance

You need an instance with a physical hard drive. Those are ones with a "d" in the name. Pick one that matches the specs listed for validator requirements on solana's docs.

Solana's Requirements here: https://docs.solana.com/running-validator/validator-reqs

If you have the budget for it, run a `c5d.metal`

## EC2 Configuration

### 1. ssh into the instance

### 2. Configure RAID.

With a `c5d.metal`, run the following:

- `sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=4 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme3n1 /dev/nvme4n1`
- `sudo mkfs.ext4 /dev/md0`
- Edit `/etc/fstab` by adding `/dev/md0 /mnt/solana ext4 rw,defaults 0 0`
- `sudo mount /dev/md0`

_If you are not using a `c5d.metal` here's a good guide on what RAID is and how to configure it: [RAID on AWS](https://bravetheheat.medium.com/configuring-raid-on-aws-ec2-214610e0983d)_

### 3. Either generate or scp your `validator-keypair.json` and your `vote-account-keypair.json`. Note: Currently the script only supports this naming convention.

### 4. Run this setup script:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/strangemoodfoundation/solana-validator/main/install_validator.sh)"
```

### 5. Update the withdraw authority

You will be marked as insecure until your withdraw-authority does not match your vote-authority.

Outside of your ec2 instance, run:
`solana-keygen new --outfile withdraw-authority.json`

In your instance run:
`solana-vote-authorize-withdrawer <VOTE_ACCOUNT_ADDRESS> wallet-keypair.json <AUTHORIZED_PUBKEY>`
ex: `solana-vote-authorize-withdrawer BGWi77i5rzvSLN37MYQqaEJdEXGXpSyTFSG2o8UUFH4U wallet-keypair.json CsUDw1RKF71bk55yC5Hehi1c1ir42JaXSZT8y7qnoiPQ`

## Monitoring

`solana-validator --ledger /mnt/solana/ledger/ monitor`

## Debugging

`htop` - where resources are used
`ufw status` - firewall config details

## Files

Validator Service: /etc/systemd/system/solana-validator.service

# Thanks 🙏🏼

Alexander Ray & the mfactory team!
