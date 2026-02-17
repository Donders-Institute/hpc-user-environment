#!/bin/bash

function getLoadedMatlabModule() {

    module=$(for i in `module list 2>&1 | grep matlab`; do echo $i; done | awk '{if ($1 ~ /^matlab/) {print $1}}')

    ## use default matlab module if not loaded explicitely
    if [ -z $module ]; then
        module="matlab"
    fi

    echo $module
}

function getLoadedMatlabModuleFromEnv() {

    loaded=$1
    module=$(for i in `echo $loaded | sed 's/:/ /g'`; do echo $i; done | awk '{if ($1 ~ /^matlab/) {print $1}}')

    ## use default matlab module if not loaded explicitely
    if [ "${module}" == "" ]; then
        module="matlab"
    fi

    ## in case there are more than one matlab modules, return the last one
    echo $module | awk '{print $NF}'
}

function rem_walltime() {
    # Function to calculate the default walltime
    # This function calculates the remaining hours/minutes until
    # 20:00 (08 pm)
    # This is used as the default walltime for torque if no walltime is
    # specified in the matlab startscript (matlabXX)...
    #
    # 07nov13 - edwger

    # Determine current time and specify end time (not 8pm but 7pm for
    # calculation purpose (hours left after calculating remaining hours)
    now=$(date +"%k:%M")
    stop="19:00"
    
    hrs_now=$((echo $now) | awk -F : '{ print $1 }')
    mins_now_1=$((echo $now) | awk -F : '{ print $2 }')

    # remove leading zeros
    mins_now="$(echo $mins_now_1 | sed 's/0*//')"

    # mins_now can be 00 and becomes empty if zeros are stripped, so...
    if [ -z $mins_now ]; then
        mins_now="0"
    fi

    if [ "$hrs_now" -ge "20" -o "$hrs_now" -lt "8" ]; then
        # Default walltime is 4 hours between 8pm and 8am (night)
        hrs_remain="04"
        mins_remain="00"
    else
        # Calculate walltime between 8am until 8pm (day)
        hrs_remain=$[19 - $hrs_now]
        mins_remain=$[60 - $mins_now]

        # mins_remain can be 60 if mins_now is 0. When mins_remain
        # equals 60 it will be changed to 00 and hrs_remain will
        # be increased by 1
        if [ "$mins_remain" -eq "60" ]; then
            mins_remain="00"
            hrs_remain=$(($hrs_remain+1))
        fi
        
        # Change walltime to 4 hours if remaining hours are less
        # then 4 hours
        if [ "$hrs_remain" -lt "4" ]; then
            hrs_remain="04"
            mins_remain="00"
        fi
    fi

    # put remaining walltime in var
    echo "$hrs_remain:$mins_remain:00"
}
