#!/bin/bash

[ $# -ne 1 ] && echo "insufficient arguments" 1>&2 && exit 1

[ ! -f ~/.pass ] && echo "require ~/.pass for sudo" 1>&2 && exit 2

echo "running convmv on $1 ..." 1>&2
cat ~/.pass | sudo -S /opt/cluster/sbin/netapp_migrate/convmv -r -f ascii -t utf-8 $1 2>&1 | grep 'already UTF-8:' | awk -F ': ' '{print $2}'
