#!/bin/bash

f=$1

grep '^/project_atreides' $f | while read src; do

    echo "$src -> $dst"
    dst=$(echo $src | sed 's|/project_atreides|/project|')
    cat ~/.pass | sudo -S rm -vrf "$dst"
    cat ~/.pass | sudo -S /usr/bin/rsync -av -X --filter='-x! system.nfs4_acl' --delete "${src}/" "${dst}"

done
