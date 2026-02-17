#!/bin/bash
#########################################################
# This script removes scratch directories created for
# torque jobs that are no longer available in the qstat.
#
# This script needs to be run with SUDO privilege. It 
# also assumes that the scratch of job is named with
# the following convention:
#
#     /data/$USER/$PBS_JOBID
#
#########################################################
for l in $( ls -d /data/*/*.dccn.nl ); do
    u=$( echo $l | awk -F '/' '{print $(NF-1)}' )
    j=$( echo $l | awk -F '/' '{print $NF}' )

    echo "check job: $j ..."
    sudo -u $u qstat $j >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "removing: $l ..."
        rm -rf $l
    fi
done
