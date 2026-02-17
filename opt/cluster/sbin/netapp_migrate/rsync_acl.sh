#!/bin/bash

[ $# -ne 2 ] && echo "insufficient arguments" 1>&2 && exit 1

[ ! -f ~/.pass ] && echo "require ~/.pass for sudo" 1>&2 && exit 2

src=$(echo $1 | sed 's|/*$||')
dst=$(echo $2 | sed 's|/*$||')

echo "syncing ${src}/ --> ${dst} ..."
cat ~/.pass | sudo -S /usr/bin/rsync -av -X --filter='-x! system.nfs4_acl' --delete "${src}/" "$dst"
