#!/bin/bash

[ $# -ne 1 ] && echo "insufficient arguments" 1>&2 && exit 1

[ ! -f ~/.pass ] && echo "require ~/.pass for sudo" 1>&2 && exit 2

echo -n "Number of files atreides: "
cat ~/.pass | sudo -S ls -altrR "/project_atreides/$1" | wc -l
echo -n "Number of files fremen  : "
cat ~/.pass | sudo -S ls -altrR "/project/$1" | wc -l
