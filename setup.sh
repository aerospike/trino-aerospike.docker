#!/bin/bash
set -e

AEROSPIKE_ENVS=0
if [ ! -z "${AS_HOSTNAME}" ] || [ ! -z "${AS_PORT}" ] || [ ! -z "${AS_HOSTLIST}" ] || \
[ ! -z "${TABLE_DESC_DIR}" ] || [ ! -z "${SPLIT_NUMBER}" ] || [ ! -z "${CACHE_TTL_MS}" ] || \
[ ! -z "${DEFAULT_SET_NAME}" ] || [ ! -z "${STRICT_SCHEMAS}" ] || [ ! -z "${RECORD_KEY_NAME}" ] || \
[ ! -z "${RECORD_KEY_HIDDEN}" ] || [ ! -z "${ENABLE_STATISTICS}" ] || [ ! -z "${INSERT_REQUIRE_KEY}" ]; then
  AEROSPIKE_ENVS=1
fi

export AS_HOSTNAME=${AS_HOSTNAME:-docker.for.mac.host.internal}
export AS_PORT=${AS_PORT:-3000}
export AS_HOSTLIST=${AS_HOSTLIST}
export TABLE_DESC_DIR=${TABLE_DESC_DIR:-/etc/trino/aerospike}
export SPLIT_NUMBER=${SPLIT_NUMBER:-4}
export CACHE_TTL_MS=${CACHE_TTL_MS:-1800000}
export DEFAULT_SET_NAME=${DEFAULT_SET_NAME:-__default}
export STRICT_SCHEMAS=${STRICT_SCHEMAS:-false}
export RECORD_KEY_NAME=${RECORD_KEY_NAME:-__key}
export RECORD_KEY_HIDDEN=${RECORD_KEY_HIDDEN:-false}
export ENABLE_STATISTICS=${ENABLE_STATISTICS:-false}
export INSERT_REQUIRE_KEY=${INSERT_REQUIRE_KEY:-false}

if [ -f /tmp/aerospike.properties.template ] && [ $AEROSPIKE_ENVS -eq 1 ]; then
  envsubst < /tmp/aerospike.properties.template > /etc/trino/catalog/aerospike.properties
fi

export TRINO_NODE_ID=$(uuidgen)
echo "TRINO_NODE_ID=$TRINO_NODE_ID"
envsubst < /tmp/trino.node.properties.template > /etc/trino/node.properties

export TRINO_DISCOVERY_URI=${TRINO_DISCOVERY_URI:-http://localhost:8080}
if [[ -z "${TRINO_NODE_TYPE}" ]]; then
    echo "Configuring a single-node Trino cluster"
elif [[ $TRINO_NODE_TYPE == "coordinator" ]]; then
    echo "Configuring a coordinator Trino node"
    envsubst < /tmp/coordinator.config.properties.template > /etc/trino/config.properties
elif [[ $TRINO_NODE_TYPE == "worker" ]]; then
    echo "Configuring a worker Trino node"
    envsubst < /tmp/worker.config.properties.template > /etc/trino/config.properties
else 
    printf '%s\n' "Invalid TRINO_NODE_TYPE parameter: $TRINO_NODE_TYPE" >&2
    exit 1
fi

chown -R trino:trino /etc/trino

/usr/lib/trino/bin/run-trino
