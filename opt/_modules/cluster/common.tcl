#!/bin/env tclsh

set appname "HPC cluster utilities" 
set appurl  ""
set appdesc "a collection of home-grown cluster utilities/scripts"

## require $version varaible to be set
module-whatis [WhatIs]
setenv CLUSTER_UTIL_ROOT $env(DCCN_OPT_DIR)/cluster
setenv CLUSTER_ADMINS "h.lee@donders.ru.nl e.gerrits@donders.ru.nl helpdesk@donders.ru.nl"
prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/sbin"
prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/bin"
prepend-path MANPATH "$env(CLUSTER_UTIL_ROOT)/man"

# add the utility binaries and libraries
if { $arch == "linux_x86_64" } {
    prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/external/utilities/bin64"
    prepend-path LD_LIBRARY_PATH "$env(CLUSTER_UTIL_ROOT)/lib"
} else {
    prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/external/utilities/bin32"
}
append-path MANPATH "$env(CLUSTER_UTIL_ROOT)/external/utilities/man"

# add p7zip tool
prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/external/p7zip-16.02/bin"
prepend-path MANPATH "$env(CLUSTER_UTIL_ROOT)/external/p7zip-16.02/man"
append-path LD_LIBRARY_PATH "$env(CLUSTER_UTIL_ROOT)/external/p7zip-16.02/lib/p7zip"

# add lzip tools
prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/external/lzip/bin"
prepend-path MANPATH "$env(CLUSTER_UTIL_ROOT)/external/lzip/share/man"

# add pigz tools (parallel gzip)
prepend-path PATH "$env(CLUSTER_UTIL_ROOT)/external/pigz/bin"
prepend-path MANPATH "$env(CLUSTER_UTIL_ROOT)/external/pigz/man"

