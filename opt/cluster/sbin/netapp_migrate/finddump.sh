#!/bin/bash

[ $# -ne 1 ] && echo "insufficient arguments" 1>&2 && exit 1

[ ! -f ~/.pass ] && echo "require ~/.pass for sudo" 1>&2 && exit 2

out_fremen=${PBS_O_WORKDIR}/$1/fremen.out
out_atreides=${PBS_O_WORKDIR}/$1/atreides.out

mkdir -p ${PBS_O_WORKDIR}/$1

echo "finddump for atreides ..."
cat ~/.pass | sudo -S find "/project_atreides/$1" -type f -exec ls -l {} \; > ${out_atreides}

echo "finddump for fremen ..."
cat ~/.pass | sudo -S find "/project/$1" -type f -exec ls -l {} \; > ${out_fremen}
