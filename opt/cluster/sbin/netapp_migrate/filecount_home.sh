#!/bin/bash

[ $# -ne 1 ] && echo "insufficient arguments" 1>&2 && exit 1

[ ! -f ~/.pass ] && echo "require ~/.pass for sudo" 1>&2 && exit 2

p_fremen=$1
p_atreides=$(echo $1 | sed 's|/home/|/home_atreides/|')

echo -n "Number of files atreides: "
cat ~/.pass | sudo -S ls -altrR "${p_atreides}" | wc -l
echo -n "Number of files fremen  : "
cat ~/.pass | sudo -S ls -altrR "${p_fremen}" | wc -l
