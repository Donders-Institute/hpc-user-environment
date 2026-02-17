#!/bin/bash

for f in *.o*; do
    n_atreides=$(grep 'atreides' $f | awk -F ':' '{print $NF}')
    n_fremen=$(grep 'fremen' $f | awk -F ':' '{print $NF}')
    echo -n $f
    [ $n_atreides -ne $n_fremen ] && echo "NOT THE SAME ($n_fremen != $n_atreides)" || echo 'THE SAME'
done
