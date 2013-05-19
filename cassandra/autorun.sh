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
#Script to autorun everything by calling install, deploy, run and data 
#collect scripts. Feel free to disable some scripts if they are not 
#necessary in your experiments.
#
#
#########################################################
#
#The script uses root + ssh key to access EC2 instances.
#So always run scripts in an experimental environment.
#Make sure to check each script for NOTE, in case of any
#conflicts to your system.
#
#########################################################

LOCATION=`pwd`

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    exit ${1}
  fi
}

CASSANDRA_INSTANCE=("CASSANDRA-1.compute.amazonaws.com" \
    			"CASSANDRA-2.compute.amazonaws.com" \
    			"CASSANDRA-3.compute.amazonaws.com")
YCSB="YCSB.compute.amazonaws.com"

echo "Deployments start at `date`"
rm ~/.ssh/known_hosts > /dev/null 2>&1

cassandra_instance_all=${CASSANDRA_INSTANCE[0]}
for ((k=1; k<${#CASSANDRA_INSTANCE[*]}; k++)) do
	cassandra_instance_all=$cassandra_instance_all" "${CASSANDRA_INSTANCE[$k]}
done

echo "Start installing Cassandra instance (1/3)"
cd "$LOCATION/install" && ./install.sh "$cassandra_instance_all" > /dev/null 2>&1
check_errs $? "Install Cassandra instances failed."

echo "Start deploying Cassandra instance (2/3)"
cd "$LOCATION/deploy" && ./deploy.sh "$cassandra_instance_all" > /dev/null 2>&1
check_errs $? "Deploy Cassandra instances failed."

echo "Start installing YCSB instance (3/3)"
cd "$LOCATION/test" && ./install.sh "$YCSB" "$cassandra_instance_all" > /dev/null 2>&1
check_errs $? "Install YCSB instances failed."

echo "Experiments end at `date`"
