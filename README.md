# kickstart-autobahn-node
An easy to use installer for an autobahn node (Mainnet and Testnet)

## Preparations
1. Setup a linux server (for example on hetzner.de as Cloud Server or on AWS as EC2 instance). We tested with Ubuntu 20.
1. Create c3labs user on host system `adduser c3labs`
1. Ensure that the user c3labs has the uid and gid 1000
    2. verify with `id c3labs`
1. Install docker.io
    2. On Ubuntu with `apt install docker.io`
1. Add user to docker group `usermod -aG docker c3labs`
1. Install docker compose v2
   [https://docs.docker.com/compose/install/linux/#install-using-the-repository](https://docs.docker.com/compose/install/linux/#install-using-the-repository)

## How to install for a member node?
### Mainnet
```
export BOOTNODES=enode://c1e03e975a2685a75816daa38f2d8501a1fa9cf2c32b0f2a3ac1c4f7c1c579087aab078ff6ac0726eb6c107da77e777d4546e0080c621a127a5aa004c6668ef6@167.235.150.0:0?discport=30310 && \
bash -c "$(curl -L https://github.com/create3labs/kickstart-autobahn-node/releases/download/v1.0.4/installer.sh)";
```
### Testnet
```
export BOOTNODES=enode://500706d4adc5a65f0454b02b3d574a112431d4d51b05572dfc9b2489e24ffd3017c6ef58dd9eea10f100806afaa212e285f5153a81422ffe128be75fa7ea015c@195.201.234.142:0?discport=30310 && \
export NETWORK=autobahn-testnet && \
export NETWORK_ID=45001 && \
bash -c "$(curl -L https://github.com/create3labs/kickstart-autobahn-node/releases/download/v1.0.4/installer.sh)";
```

### How to start?
The system should start automatically.
Check with: `docker logs -f member`