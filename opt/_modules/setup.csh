#!/bin/csh

source /etc/profile.d/modules.csh

#setenv TMPDIR /tmp
setenv DCCN_OPT_DIR /opt
setenv DCCN_MOD_DIR ${DCCN_OPT_DIR}/_modules

setenv MODULEPATH $DCCN_MOD_DIR:${DCCN_OPT_DIR}/neurodesk/neurocommand/local/containers/modules
