#!/usr/bin/env bash
# Function: use for set up kubernetes test infrastructure
# Params:
# Version: 0.1

# Copyright 2017 The liuqi.edward@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Bring up a Kubernetes cluster.
#
# If the full release name (gs://<bucket>/<release>) is passed in then we take
# that directly.  If not then we assume we are doing development stuff and take
# the defaults in the release config.

set -o errexit
set -o nounset
set -o pipefail


KUBE_ROOT=$(dirname "${BASH_SOURCE}")/../..
readonly ROOT=$(dirname "${BASH_SOURCE}")
source "${ROOT}/${KUBE_CONFIG_FILE:-"config-default.sh"}"

function check-vm-exist() {
    if nova show $1 >> /dev/null; then
        return 1
    else
        return 0
    fi
}
function delete-instances() {
    if check-vm-exist ${MASTER_NAME}; then
        nova force-delete ${MASTER_NAME}
        local ins_id
        for i in `seq 1 ${NUMBER_OF_ROUTERS}`
        do
            for j in `seq 1 ${NUMBER_OF_NETWORKS}`
            do
                for k in `seq 1 ${NUMBER_OF_MINIONS_PER_NET}`
                do
                    ins_id=$(echo $i * $j + $k|bc)
                    if check-vm-exist ${MINION_NAME_PREFIX}${ins_id}; then
                        echo "[INFO] delete "${MINION_NAME_PREFIX}${ins_id}"..."
                        nova force-delete ${MINION_NAME_PREFIX}${ins_id}
                    fi
                done
            done
        done
    fi
}

function delete-router() {
    for i in `seq 1 ${NUMBER_OF_ROUTERS}`
    do
        for j in `seq 1 ${NUMBER_OF_NETWORKS}`
        do
            neutron router-interface-delete ${ROUTER_PREFIX}-${i} ${NETWORK_PREFIX}-${j}-${SUBNET_PREFIX}
        done
        neutron router-gateway-clear ${ROUTER_PREFIX}-${i}
        neutron router-delete ${ROUTER_PREFIX}-${i}
    done
}

function delete-networks() {
    echo '[INFO] delete ${NUMBER_OF_NETWORKS} network'
    for i in `seq 1 ${NUMBER_OF_NETWORKS}`
    do
	    neutron subnet-delete ${NETWORK_PREFIX}-${i}-${SUBNET_PREFIX}
        neutron net-delete ${NETWORK_PREFIX}-${i}
    done
}

function vm-down() {
    echo '[INFO] start clean up environment'

    delete-instances

    delete-router

    delete-networks
}

vm-down
