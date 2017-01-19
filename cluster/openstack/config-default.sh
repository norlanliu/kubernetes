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

NUMBER_OF_ROUTERS=${NUMBER_OF_ROUTERS:-1}

ROUTER_PREFIX=${ROUTER_PREFIX:-kube-router}

NUMBER_OF_NETWORKS=${NUMBER_OF_NETWORKS:-4}

NETWORK_PREFIX=${NETWORK_PREFIX:-kube-network}

SUBNET_PREFIX=${SUBNET_PREFIX:-sub}

SUBNET_CIDR_TEMPLATE=${SUBNET_CIDR_TEMPLATE:-192.168.@.0/24}

SUBNET_PREFIX=${NETWORK_PREFIX:-kube-subnet}

NUMBER_OF_MINIONS_PER_NET=${NUMBER_OF_MINIONS_PER_NET:-2}

NUMBER_OF_MASTERS=${NUMBER_OF_MASTERS:-1}

MASTER_FLAVOR=${MASTER_FLAVOR:-k1.large}

MINION_FLAVOR=${MINION_FLAVOR:-k1.medium}

MINION_NAME_PREFIX=${MINION_NAME_PREFIX:-kubenode}

MASTER_NAME=${MASTER_NAME:-kubemaster}

EXTERNAL_NETWORK=${EXTERNAL_NETWORK:-ext-net}

# Flag indicates if new image must be created. If 'false' then image with IMAGE_ID will be used.
# If 'true' then new image will be created from file config-image.sh
CREATE_IMAGE=${CREATE_IMAGE:-true} # use "true" for devstack

# Flag indicates if image should be downloaded
DOWNLOAD_IMAGE=${DOWNLOAD_IMAGE:-true}

# Image id which will be used for kubernetes stack
IMAGE_ID=${IMAGE_ID:-f0f394b1-5546-4b68-b2bc-8abe8a7e6b8b}

# DNS server address
DNS_SERVER=${DNS_SERVER:-8.8.8.8}

# Public RSA key path
CLIENT_PUBLIC_KEY_PATH=${CLIENT_PUBLIC_KEY_PATH:-~/.ssh/id_rsa.pub}
