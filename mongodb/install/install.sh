#!/bin/bash
#
#  Copyright 2013 Liang Zhao <alpha.roc@gmail.com>
#
#  Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#Script to install all necessary tools.
#

if [ "${#}" -lt "1" ]; then
  echo "This script takes addresses of Ubuntu instances to install "
  echo "MongoDB and other softwares for the test environment."
  echo ""
  echo "Usage:"
  echo "   ${0} [MongoDB]"
  exit 0
fi

MONGODB_INSTANCE="${1}"

# Acquire SSH policy
# It is a pre-requirement of all following installation 
install_ssh_policy()
{
  # Grand root access
  ssh ubuntu@$1 "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/"
}

# Install MongoDB
install_mongodb()
{
  # Add MongoDB repository
  ssh root@$1 "echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list"
  # Install public keys for MongoDB
  ssh root@$1 "apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10"
  # Install MongoDB
  ssh root@$1 "apt-get update \
  && aptitude -y install mongodb-10gen"
  # Stop MongoDB
  ssh root@$1 "service mongodb stop"
}

setup_mongodb_inst()
{
  # Install SSH policy
  install_ssh_policy $1

  # Install MongoDB database
  install_mongodb $1
}

# Setup MongoDB instance
for mongodb in $MONGODB_INSTANCE; do
  setup_mongodb_inst $mongodb > /dev/null &
done
wait
