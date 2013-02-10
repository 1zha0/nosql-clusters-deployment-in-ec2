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

if [ "${#}" -lt "2" ]; then
  echo "This script takes addresses of Ubuntu instances to install "
  echo "YCSB and other softwares for the test environment."
  echo ""
  echo "Usage:"
  echo "   ${0} [YCSB] [CASSANDRA]"
  exit 0
fi

YCSB="${1}"
CASSANDRA_INSTANCE="${2}"

install_ssh_policy()
{
  # Grand root access
  ssh ubuntu@$1 "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/"
}

# Install YCSB
install_ycsb()
{
  for cassandra in $CASSANDRA_INSTANCE; do
    hosts=$hosts"$cassandra,"
  done
  hosts=${hosts%?}

  # Download YCSB
  ssh root@$1 "wget https://github.com/downloads/brianfrankcooper/YCSB/ycsb-0.1.4.tar.gz --no-check-certificate"
  ssh root@$1 "tar xfvz ycsb-0.1.4.tar.gz"
  ssh root@$1 "rm ycsb-0.1.4.tar.gz"

  # Download bindings
  ssh root@$1 "wget http://archive.apache.org/dist/cassandra/1.2.1/apache-cassandra-1.2.1-bin.tar.gz"
  ssh root@$1 "tar xfvz apache-cassandra-1.2.1-bin.tar.gz"
  ssh root@$1 "cp ~/apache-cassandra-1.2.1/lib/*.jar ~/ycsb-0.1.4/cassandra-binding/."
  ssh root@$1 "rm -Rf apache-cassandra-1.2.1*"
  ssh root@$1 "echo \"hosts=$hosts\" >> ycsb-0.1.4/workloads/workloada"
  ssh root@$1 "chmod +x ycsb-0.1.4/bin/ycsb"
}

setup_ycsb_inst()
{
  # Install SSH policy, Java runtime environment, Faban system
  install_ssh_policy $1

  # Install YCSB database
  install_ycsb $1
}

# Setup YCSB instance
  setup_cassandra_inst $HOST > /dev/null &
done
wait

