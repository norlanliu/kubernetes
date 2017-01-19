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
    if nova show $1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check-router-exist() {
    if neutron router-show $1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check-subnet-exist() {
    if neutron subnet-show $1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check-net-exist() {
    if neutron net-show $1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function delete-flavor() {
    echo '[INFO] delete flavor...'
    if nova flavor-show ${MINION_FLAVOR} > /dev/null 2>&1;then
        nova flavor-delete ${MINION_FLAVOR}
    fi
    if nova flavor-show ${MASTER_FLAVOR} > /dev/null 2>&1;then
        nova flavor-delete ${MASTER_FLAVOR}
    fi
}
function delete-instances() {
    echo '[INFO] delete instances...'
    if check-vm-exist ${MASTER_NAME}; then
        echo "[INFO] delete "${MASTER_NAME}
        nova force-delete ${MASTER_NAME}
    fi
    local num_of_instances=$(echo ${NUMBER_OF_ROUTERS}*${NUMBER_OF_NETWORKS}*${NUMBER_OF_MINIONS_PER_NET}|bc)
    for i in `seq 1 ${num_of_instances}`
    do
        if check-vm-exist ${MINION_NAME_PREFIX}${i}; then
            echo "[INFO] delete "${MINION_NAME_PREFIX}${i}"..."
            nova force-delete ${MINION_NAME_PREFIX}${i}
        fi
    done
}

function delete-router() {
    echo '[INFO] delete routers...'
    for i in `seq 1 ${NUMBER_OF_ROUTERS}`
    do
        if check-router-exist ${ROUTER_PREFIX}-${i}; then
            for j in `seq 1 ${NUMBER_OF_NETWORKS}`
            do
                neutron router-interface-delete ${ROUTER_PREFIX}-${i} ${NETWORK_PREFIX}-${j}-${SUBNET_PREFIX}
            done
            neutron router-gateway-clear ${ROUTER_PREFIX}-${i}
            neutron router-delete ${ROUTER_PREFIX}-${i}
        fi
    done
}

function delete-networks() {
    echo '[INFO] delete networks...'
    for i in `seq 1 ${NUMBER_OF_NETWORKS}`
    do
        if check-subnet-exist ${NETWORK_PREFIX}-${i}-${SUBNET_PREFIX}; then
            neutron subnet-delete ${NETWORK_PREFIX}-${i}-${SUBNET_PREFIX}
        fi
        if check-net-exist ${NETWORK_PREFIX}-${i}; then
            neutron net-delete ${NETWORK_PREFIX}-${i}
        fi
    done
}

function vm-down() {
    echo '[INFO] start clean up environment'

    delete-instances

    delete-router

    delete-flavor

    delete-networks
    
    echo 'done'
}

vm-down
