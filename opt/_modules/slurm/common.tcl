#!/bin/env tclsh

## require $version varaible to be set
set appname "Slurm"
set appurl "https://slurm.schedmd.com/quickstart.html" 
set appdesc "Slurm is an open source, fault-tolerant, and highly scalable cluster management and job scheduling system." 

module-whatis [WhatIs]
prepend-path PATH "$env(DCCN_OPT_DIR)/cluster/bin/slurm"
