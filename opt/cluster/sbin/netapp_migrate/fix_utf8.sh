#!/bin/bash

f=$1

grep '^/project_atreides' $f | while read src; do

    #if [ -d "$src" ]; then
    #     echo "nothing"
    #    cat ~/.pass | sudo -S rm -rf "$dst"
    #    cat ~/.pass | sudo -S /usr/bin/rsync -av -X --filter='-x! system.nfs4_acl' --delete "${src}/" "$dst"
    #else
    #    cat ~/.pass | sudo -S rm -f "$dst"
    #    cat ~/.pass | sudo -S /usr/bin/rsync -av -X --filter='-x! system.nfs4_acl' "${src}" "$dst"
    #fi

    cat ~/.pass | sudo -S ls -ld "$src" | grep '^d'

    if [ $? -ne 0 ]; then
        dst=$(echo $src | sed 's|/project_atreides|/project|')
        echo "$src -> $dst"
        cat ~/.pass | sudo -S rm -vf "$dst"
        cat ~/.pass | sudo -S /usr/bin/rsync -av -X --filter='-x! system.nfs4_acl' "${src}" "$dst"
        pdir=$(dirname "$dst")

        # clean up files/directories with ':' as prefix
        echo "clean ${pdir}"
        cat ~/.pass | sudo -S rm -vf "${pdir}/:*"
    fi
    #cat ~/.pass | sudo -S find "${pdir}" -name ':*' -exec rm -rf {} \;
done
