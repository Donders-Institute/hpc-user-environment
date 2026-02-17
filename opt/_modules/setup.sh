#!/bin/bash

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

    ## assume the opt dir is one level up
    dirname $DIR
}

source /etc/profile.d/modules.sh

if [ -z $DCCN_OPT_DIR ]; then
    export DCCN_OPT_DIR=`get_opt_dir`
fi

export DCCN_MOD_DIR=${DCCN_OPT_DIR}/_modules
export DCCN_32_DIR=${DCCN_OPT_DIR}/32bit

export MODULEPATH=$DCCN_MOD_DIR:${DCCN_OPT_DIR}/neurodesk/neurocommand/local/containers/modules
