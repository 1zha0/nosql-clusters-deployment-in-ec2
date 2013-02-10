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
#Script to deploy all necessary tools.
#

if [ "${#}" -lt "1" ]; then
  echo "This script takes addresses of Cassandra instances, "
  echo "to deploy the test environment."
  echo ""
  echo "Usage:"
  echo "   ${0} [Faban]"
  exit 0
fi

CASSANDRA_INSTANCE="${1}"

deploy_cassandra()
{
  # Stop Cassandra system
  ssh root@$1 "service cassandra stop"
  # Clear the data from the default directories
  ssh root@$1 "rm -rf /var/lib/cassandra/* "

  public_ip=`ssh root@$1 "curl http://instance-data/latest/meta-data/public-ipv4"`
  local_ip=`ssh root@$1 "curl http://instance-data/latest/meta-data/local-ipv4"`

  # Configure Cassandra
  scp -r ./conf/cassandra-rackdc.properties root@$1:/etc/cassandra/cassandra-rackdc.properties

  cp ./conf/cassandra.yaml ./cassandra_$2.yaml && \
  perl -p -i -e "s/#CLUSTER_NAME#/"YCSB"/" cassandra_$2.yaml && \
  perl -p -i -e "s/#SEED_INSTANCE#/$3/" cassandra_$2.yaml && \
  perl -p -i -e "s/#LOCAL_IPV4#/$local_ip/" cassandra_$2.yaml && \
  perl -p -i -e "s/#PUBLIC_IPV4#/$public_ip/" cassandra_$2.yaml

  scp -r cassandra_$2.yaml root@$1:/etc/cassandra/cassandra.yaml && \
  rm cassandra_$2.yaml
  # Staring Cassandra system
  ssh root@$1 "service cassandra start"
}

# Deploy Cassandra system
num_agent=0
for agent in $CASSANDRA_INSTANCE; do
  num_agent=$[$num_agent+1]
  if [ "$num_agent" -eq "1" ]; then
    # Initializing Cassandra
    seed_cassandra=`ssh root@$agent "curl http://instance-data/latest/meta-data/public-ipv4"`
  fi
done

num_agent=0
for agent in $CASSANDRA_INSTANCE; do
  num_agent=$[$num_agent+1]
  deploy_cassandra $agent $num_agent $seed_cassandra &
done
wait

