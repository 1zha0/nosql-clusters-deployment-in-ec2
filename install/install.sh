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
  echo "Cassandra and other softwares for the test environment."
  echo ""
  echo "Usage:"
  echo "   ${0} [Cassandra]"
  exit 0
fi

CASSANDRA_INSTANCE="${1}"

# Acquire SSH policy
# It is a pre-requirement of all following installation 
install_ssh_policy()
{
  # Grand root access
  ssh ubuntu@$1 "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/"
}

# Install Cassandra
install_cassandra()
{
  # Add Cassandra repository
  ssh root@$1 "echo \" \" >> /etc/apt/sources.list"
  ssh root@$1 "echo \"deb http://www.apache.org/dist/cassandra/debian 12x main\" >> /etc/apt/sources.list"
  ssh root@$1 "echo \"deb-src http://www.apache.org/dist/cassandra/debian 12x main\" >> /etc/apt/sources.list"
  # Install public keys for Cassandra
  ssh root@$1 "gpg --keyserver keyserver.ubuntu.com --recv-keys F758CE318D77295D \
  && gpg --export --armor F758CE318D77295D | apt-key add - \
  && gpg --keyserver keyserver.ubuntu.com --recv-keys 2B5C1B00 \
  && gpg --export --armor 2B5C1B00 | apt-key add -"
  # Install Cassandra
  ssh root@$1 "apt-get update \
  && aptitude -y install cassandra \
  && echo 'export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64' | cat - ~/.bashrc > ~/.bashrc_r \
  && mv ~/.bashrc_r ~/.bashrc"
  # Stop Cassandra
  ssh root@$1 "service cassandra stop"
}

setup_cassandra_inst()
{
  # Install SSH policy
  install_ssh_policy $1

  # Install Cassandra database
  install_cassandra $1
}

# Setup Cassandra instance
for cassandra in $CASSANDRA_INSTANCE; do
  setup_cassandra_inst $cassandra > /dev/null &
done
wait

