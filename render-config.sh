#!/usr/bin/env bash
# Renders ./config/public_full_node.yaml and ./config/reth_config.json.
# Templates are fetched directly from Galxe/gravity-sdk (same "curl the
# specific file" pattern as Jovay's genesis.conf/VERSION download) — no
# repo clone needed.
#
# Requires: envsubst (GNU gettext), jq, curl

set -euo pipefail

set -a
# shellcheck disable=SC1091
. ./.env
set +a

TPL_BASE="https://raw.githubusercontent.com/Galxe/gravity-sdk/main/cluster/templates"

# Seed block per the Gravity team's breaking-change notice: only rpc-4 is
# active. Original rpc-1/rpc-3 seeds commented out — do NOT re-enable
# without confirming with the Gravity team. 0x-prefixed peer_id confirmed
# as the correct format for this YAML seeds block.
export PFN_SEEDS_BLOCK='    seeds:
      # -- disabled per Gravity team breaking-change notice --
      # "0x38013b46c21388c3fd08ab32b86b478b3109125566d63c2da8fdc941dc474077":
      #   addresses:
      #     - "/dns/mainnet-rpc-p2p-1.gravity.xyz/tcp/6180/noise-ik/234aee14677a3d2198208ea72ca5e95ed75520df27f01f0c36220303ff78642f/handshake/0"
      #   role: PreferredUpstream
      # "0x2d30cf69303d40e0efcdb0f3a6545d43b055e86729287f2f1328c001caeb2be4":
      #   addresses:
      #     - "/dns/mainnet-rpc-p2p-3.gravity.xyz/tcp/6180/noise-ik/0a71ef75482f617203f64b0d5e9e3a66361b5f35e9d709ef873c494cd76d2365/handshake/0"
      #   role: PreferredUpstream
      "0x2a45f016fcd7798df5e525b8acda5af597838439e35cee8dab26f80d904385a7":
        addresses:
          - "/dns/mainnet-rpc-p2p-4.gravity.xyz/tcp/6180/noise-ik/c55a7fc6d36b6bad00363e17c31cf38690d307ec9b14ecd5d8170aa67adb5c61/handshake/0"
        role: PreferredUpstream'

mkdir -p config

curl -fsSL "${TPL_BASE}/public_full_node.yaml.tpl" | envsubst > config/public_full_node.yaml

if [[ -n "${PRUNE_TRANSACTIONLOOKUP_DISTANCE:-}" ]]; then
  curl -fsSL "${TPL_BASE}/reth_config_pfn_prune.json.tpl" | envsubst > config/reth_config.json
else
  curl -fsSL "${TPL_BASE}/reth_config_pfn.json.tpl" | envsubst > config/reth_config.json
fi

echo "Rendered config/public_full_node.yaml and config/reth_config.json"
jq . config/reth_config.json > /dev/null && echo "reth_config.json OK"
grep -n 'PreferredUpstream\|mainnet-rpc-p2p-4.gravity.xyz\|/gravity/config/identity.yaml' config/public_full_node.yaml
