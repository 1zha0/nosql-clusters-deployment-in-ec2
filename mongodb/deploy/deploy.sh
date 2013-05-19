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
#MONGODB
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#Script to deploy all necessary tools.
#

if [ "${#}" -lt "1" ]; then
  echo "This script takes addresses of MongoDB instances, "
  echo "to deploy the test environment."
  echo ""
  echo "Usage:"
  echo "   ${0} [MongoDB]"
  exit 0
fi

MONGODB_INSTANCE="${1}"

deploy_mongodb()
{
  # Stop MongoDB system
  ssh root@$1 "service mongodb stop"
  # Clear the data from the default directories
  ssh root@$1 "rm -rf /var/lib/mongodb/* "
  ssh root@$1 "rm -rf /var/log/mongodb/mongodb.log"


  # Configure MongoDB
  cp ./conf/mongodb.conf ./mongodb_$2.conf && \
  scp -r mongodb_$2.conf root@$1:/etc/mongodb.conf
  rm mongodb_$2.conf

  # Staring MongoDB system
  ssh root@$1 "service mongodb start"
}

# Deploy MongoDB system
num_agent=0
for agent in $MONGODB_INSTANCE; do
  num_agent=$[$num_agent+1]
  deploy_mongodb $agent $num_agent &
done
wait

# Reconfig MongoDB system with script replSet.js
num_agent=0
cp ./conf/replSet.js ./replSet_conf.js
for agent in $MONGODB_INSTANCE; do
  num_agent=$[$num_agent+1]
  public_hostname=`ssh root@$agent "curl http://instance-data/latest/meta-data/public-hostname"`
  if [ "$num_agent" -eq "1" ]; then
    # Initializing MongoDB
    master_mongodb=$public_hostname
    perl -p -i -e "s/#MASTER_MONGODB#/$public_hostname/" replSet_conf.js
  else
    echo "rs.add(\"$public_hostname:27017\")" >> replSet_conf.js
  fi
done
echo "rs.config()" >> replSet_conf.js
scp -r replSet_conf.js root@$master_mongodb:~/replSet.js
rm replSet_conf.js

# The following command is commented out because running so (i.e. 
# "ssh root@host 'mongo < ~/replSet.js'" as a single command line 
# embedded in script) always return inconsistent results. It gives 
# "connection failure" sometimes. But if you do a remote login via 
# "ssh root@host" and then execute the "mongo" command in remote 
# manner. There is no problem. So, it is better to run this command 
# manually.
#ssh root@$master_mongodb "mongo < ~/replSet.js"
