#!/bin/bash
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

# Verify prereqs on host machine
function verify-prereqs() {
 # Check the OpenStack command-line clients
 for client in neutron glance nova heat openstack;
 do
  if which $client >/dev/null 2>&1; then
    echo "${client} client installed"
  else
    echo "${client} client does not exist"
    echo "Please install ${client} client, and retry."
    exit 1
  fi
 done
}

# create networks
function create-network() {
    echo '[INFO] Create ${NUMBER_OF_NETWORKS} network'
    local cidr
    for i in `seq 1 ${NUMBER_OF_NETWORKS}`
    do
        neutron net-create ${NETWORK_PREFIX}-${i}
        cidr=$(sed 's/@/'${i}'/g' <<< ${SUBNET_CIDR_TEMPLATE})
	neutron subnet-create --name ${NETWORK_PREFIX}-${i}-${SUBNET_PREFIX} --ip-version 4 --dns-nameserver 114.114.114.114 --dns-nameserver 8.8.8.8  ${NETWORK_PREFIX}-${i} ${cidr}
    done
}

# Create router
function create-router() {
    echo '[INFO] Create routers'
    for i in `seq 1 ${NUMBER_OF_ROUTERS}`
    do
        neutron router-create ${ROUTER_PREFIX}-${i}
        neutron router-gateway-set ${ROUTER_PREFIX}-${i} --external-gateway ${EXTERNAL_NETWORK}
        for j in `seq 1 ${NUMBER_OF_NETWORKS}`
        do
            neutron router-interface-add ${ROUTER_PREFIX}-${i} ${NETWORK_PREFIX}-${j}-${SUBNET_PREFIX}
        done
    done
}

function check-flavor() {
    if nova flavor-show $1 > /dev/null 2>&1;then
        return 1
    else
        return 0
    fi
}

# create flaovor
function create-flavor() {
    echo '[INFO] Create flavors ...'
    if check-flavor ${MINION_FLAVOR};then
        nova flavor-create ${MINION_FLAVOR} auto ${MINION_FLAVOR_CONF_RAM} ${MINION_FLAVOR_CONF_DISK} ${MINION_FLAVOR_CONF_VCPUS}
    fi
    if check-flavor ${MASTER_FLAVOR};then
        nova flavor-create ${MASTER_FLAVOR} auto ${MASTER_FLAVOR_CONF_RAM} ${MASTER_FLAVOR_CONF_DISK} ${MASTER_FLAVOR_CONF_VCPUS}
    fi
}

# Create instances
function create-instances() {
    echo '[INFO] Create instances...'
    local num_of_instances=$(echo ${NUMBER_OF_ROUTERS}*${NUMBER_OF_NETWORKS}*${NUMBER_OF_MINIONS_PER_NET}|bc)
    local minion_id=1
    for i in `seq 1 ${NUMBER_OF_ROUTERS}`
    do
        for j in `seq 1 ${NUMBER_OF_NETWORKS}`
        do
	    for k in `seq 1 ${NUMBER_OF_MINIONS_PER_NET}`
            do
		echo "Create "${MINION_NAME_PREFIX}${minion_id}"..."
		nova boot --flavor ${MINION_FLAVOR} --image ${IMAGE_ID} --key-name LQ-FEDORA --security-group default --nic net-name=${NETWORK_PREFIX}-${j} ${MINION_NAME_PREFIX}${minion_id}
                minion_id=$(( $minion_id + 1 ))
            done
        done
    done
}

# Create master
function create-master() {
    echo '[INFO] Create master'
    nova boot --flavor ${MASTER_FLAVOR} --image ${IMAGE_ID} --key-name LQ-FEDORA --security-group default --nic net-name=${NETWORK_PREFIX}-1 ${MASTER_NAME}
    floatingip=$(neutron floatingip-create ${EXTERNAL_NETWORK}| grep 'floating_ip_address' | tr -d '[:space:]' | awk -F'|' '$2=="floating_ip_address"{print $3}')
    nova floating-ip-associate ${MASTER_NAME} ${floatingip}
    echo "Master ip: ${floatingip}" 1>&2
}

function vm-up() {
    echo '[INFO] start deploy the environment'

    verify-prereqs

    create-network

    create-router

    create-flavor

    create-instances

    create-master
}

vm-up
