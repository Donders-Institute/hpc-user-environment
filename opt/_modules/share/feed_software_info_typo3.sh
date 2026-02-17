#!/bin/bash

sw_base="/mnt/software"

source $sw_base/_modules/setup.sh

sw_list=$( for m in `module avail -L 2>&1 | grep -v '_modules'`; do echo $m | sed 's/(default)//g'; done | sort )

echo "<strong>Software</strong>|<strong>Description</strong>|<strong>Responsible</strong>"

for sw in $sw_list; do

    sw_name=$(dirname $sw)
    sw_version=$(basename $sw)

    uid="root"
    gid="tg"
    if [ -d ${sw_base}/${sw_name} ]; then
        uid=$( ls -ld ${sw_base}/${sw_name} | awk '{print $3}' )
        gid=$( ls -ld ${sw_base}/${sw_name} | awk '{print $4}' )
    fi

    if [ "$uid" == "root" ]; then
        [ "$gid" == "tg" ] &&
            uname="<a href=\"mailto:helpdesk@fcdonders.ru.nl\">TG</a>" ||
            uname=""
    else
        uname=$( pinky -l $uid | grep 'In real life:' | awk -F 'In real life:' '{print $NF}' | sed 's/^\s*//g' )
    fi

    module_data=$( module whatis $sw 2>&1 | egrep -o -e "${sw}:.*" | awk -F ': ' '{print $NF}' | sed 's/\s*|\s*/|/g' | awk -F '|' '{ if ($3 ~ /http/) {print "<a href=\""$3"\">"$2"</a>|"$5; } else if ($4 ~ /http/ ) { print "<a href=\""$4"\">"$2"</a>|"$5; } else { print $2"|"$5}; }')
    
    echo "$module_data|$uname"

done | sort | uniq
