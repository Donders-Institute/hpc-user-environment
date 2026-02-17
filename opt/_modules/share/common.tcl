#!/bin/env tclsh

## load library for sending UDP message
load $env(DCCN_OPT_DIR)/_modules/share/libudp1.0.11.so

## determin system architecture
proc get_sys_arch { }  {
    set arch [exec uname -m]
    if { "$arch" == "x86_64" } then {
        set my_arch "linux_x86_64"
    } else {
        set my_arch "linux_i686"
    }

    return $my_arch
}

## determin centos version
proc get_redhat_version { }  {
    regexp {^(\S+)[\s,[:alpha:]]*([0-9,\.]+).*} [exec cat /etc/redhat-release] matched os_name os_version

    return $os_version 
}

## ensure only one version at a time
proc force_one_version { } {

    global version

    set module_name [file dirname [module-info name]]
  
    if { [ module-info mode load ] } {
        if { [is-loaded $module_name] && ! [is-loaded $module_name/$version] } {
            module unload $module_name
        }
    }
}

## check if given version is centos7 only
proc centos7_only { } {

    global version
    set module_name [file dirname [module-info name]]

    set f $::env(DCCN_MOD_DIR)/$module_name/centos7-only.txt

    if { ! [file exists $f] } {
        puts stderr "file $f not found"
        return 0
    }

    set fp [open "$f" r]
    set centos7_only_versions [read $fp]
    close $fp

    foreach v [split $centos7_only_versions "\n"] {
        if { $version == [string trimright $v] } {
            return 1
        }
    }

    return 0
}

## send module name to a remote UDP endpoint
proc send_usage {{host localhost} {port 9999}} {
    if { [ module-info mode load ] } {
        package require udp
        set s [udp_open]
        udp_conf $s $host $port
        fconfigure $s -buffering none -translation binary
        puts -nonewline $s [module-info name]
    }
}

## common ModulesHelp function
proc ModulesHelp { } {
    global appname appurl appdesc version arch

    puts stderr "Set up the environment for $appname"
    puts stderr "\nVersion $version Archtecture $arch."
    puts stderr "\nWebsite: $appurl"
    puts stderr "\nDescription:\n\n$appdesc\n"

    ## extra message for support
    puts stderr "----------- Software Support --------------------------------------\n"
    puts stderr "Should you have further question concerning this software, you could\n"
    puts stderr "  - contact the software maintainer directly (see https://intranet.donders.ru.nl/index.php?id=torque-software), or"
    puts stderr "  - ask for advice from other users on the HPC Mattermost channel (see https://intranet.donders.ru.nl/index.php?id=mattermost), or"
    puts stderr "  - send a request to the TG via <helpdesk@fcdonders.ru.nl>\n"

    ## extra message for taking maintainership
    puts stderr "If you find that there is no maintainer for this software, please consider take the maintainership to help yourself and other potential users. Thanks!\n"
}

## common WhatIs function
proc WhatIs { } {
    global appname appurl docurl appdesc

    ## set default appurl if not specified
    if { ! [info exists appurl] } {
        set appurl ""
    }

    ## set empty docurl
    if { ! [info exists docurl] } {
        set docurl ""
    }

    ## set empty appdesc 
    if { ! [info exists appdesc] } {
        set appdesc ""
    }

    return "|$appname|$appurl|$docurl|$appdesc|"
}
