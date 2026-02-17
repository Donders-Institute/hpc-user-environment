#!/bin/bash
###############################################################################
# this script is run every time a user logs in on one of the linux
# computers in the cluster

function get_opt_dir() {
    ## resolve the base directory of this script 
    SOURCE="${BASH_SOURCE[0]}"

    while [ -h "$SOURCE" ]; do
      # resolve $SOURCE until the file is no longer a symlink
      DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
      SOURCE="$(readlink "$SOURCE")"
  
      # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
      [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done

    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    echo $DIR
}

# edwger: unset DBUS_SESSION_BUS_ADDRESS variable (AlmaLinux 8)
# With this annoying dbus variable set we experience various problems.
# When set for example only one firefox session can be started
# in an interactive session (error: Firefox is already running).
if [ ! -z $DBUS_SESSION_BUS_ADDRESS ]
then
   unset DBUS_SESSION_BUS_ADDRESS
fi
if [ ! -z $SESSION_MANAGER ]
then
   unset SESSION_MANAGER
fi


# Prompt definition
[ "$PS1" = "\\s-\\v\\\$ " ] && export PS1="[\u@\h \W]\\$ "

# Newer GNOME version in CentOS 7.2 requires to have environment locale setting
# of UTF-8 (8-bit Unicode Transformation Format). Old default was en_US...
export LANG="en_US.UTF-8"

# loading modules-enabled applications
export DCCN_OPT_DIR=`get_opt_dir`

source $DCCN_OPT_DIR/_modules/setup.sh

## do not load any module if it is a torque job
if [ -z $PBS_JOBID ]; then
   t1=$(date +%s%N)
   module load cluster
   module load matlab
   module load R
   module load freesurfer
   module load fsl
   module load apptainer
   if /bin/hostname |grep -v grep |grep -E -w 'mentat001|mentat002|mentat002c|mentat003|mentat004|mentat005|mentat006|mentat007' > /dev/null
   then
      module load slurm
   fi

   t2=$(date +%s%N)
   tt=$( echo "scale=3; 1.0 * ( $t2 - $t1 ) / 1000000000" | bc )

   ## showing currently loaded software modules
   if [ ! -z $TERM ] && [ $TERM != 'dumb' ]; then
       echo 
       printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
       module list
       printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
       echo "module loading time: $tt seconds"
       echo
   fi 
fi
