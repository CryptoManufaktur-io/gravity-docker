# gravity-docker

Docker Compose for a self-hosted [Gravity Mainnet](https://docs.gravity.xyz/gravity-networks/run-a-mainnet-pfn-with-docker) (L1, chain ID `127001`) PFN/RPC node.

## Setup

```bash
cp default.env .env
nano .env  # set DOMAIN, RPC_HOST, RPC_LB, SHARE_IP, PUBLIC_PORT, GRAVITY_SNAPSHOT_DATE
```

## First Run

```bash
mkdir -p config
curl -fsSL https://raw.githubusercontent.com/Galxe/gravity-sdk/main/genesis/mainnet/genesis.json -o config/genesis.json
curl -fsSL https://raw.githubusercontent.com/Galxe/gravity-sdk/main/genesis/mainnet/waypoint.txt -o config/waypoint.txt

IMAGE="ghcr.io/galxe/gravity_node:v1.9.1"
docker run --rm -v "$(pwd)/config:/gravity/config" --entrypoint gravity_cli "${IMAGE}" \
  genesis generate-key --output-file /gravity/config/identity.yaml \
  --public-output-file /gravity/config/identity.public.yaml

bash render-config.sh
```

## Snapshot Restore

```bash
SNAPSHOT_DATE=<YYYY-MM-DD>
curl -L --fail --continue-at - \
  "https://storage.googleapis.com/gravity-public-bucket/gravity-mainnet-data/${SNAPSHOT_DATE}.tar" \
  -o "/tmp/${SNAPSHOT_DATE}.tar"

docker compose run --rm --no-deps --user root --entrypoint sh \
  -e SNAPSHOT_DATE -v /tmp:/snapshot:ro gravity -c \
  'mkdir -p /gravity/data/data && \
   tar -xf "/snapshot/${SNAPSHOT_DATE}.tar" -C /gravity/data/data && \
   chown -R 10001:10001 /gravity/data /gravity/logs'
```

## Start

```bash
docker compose --env-file .env up -d
docker compose logs -f
```

## Verify

```bash
docker compose exec gravity curl -s http://127.0.0.1:8545 \
  -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```
