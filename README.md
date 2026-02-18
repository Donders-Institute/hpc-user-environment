# Wrapper scripts and shared module files for HPC cluster

This repository contains essential wrapper scripts and shared module files located in the `/opt` directory on the DCCN HPC cluster.

## Development

For testing wrapper scripts in [`opt/cluster`](opt/cluster), one can run scripts via [test_run](test_run) to be sure the variables `$PATH` and `$CLUSTER_UTIL_ROOT` are set to the local directory.  For example,

```bash
$ ./test_run opt/cluster/bin/slurm/sbash
```

## Deployment

Files are organized according to their destination structure.  Use the [Makefile](Makefile) to copy them to the destination location.  E.g.

```bash
$ make
```

By default, the destination top-level directory is `/mnt/software` and it performs a dryrun. The top-level directory can be changed by `PREFIX` while the dryrun can be turned off by `DRYRUN=false`, e.g.

```bash
$ make PREFIX=/opt DRYRUN=false
```

The [GUN make](https://www.gnu.org/software/make/) only deploy the file when the destination doesn't exist or the destination's last modification time is not later than the file in question.  One can force the deployment using the `-B` option of `make`.

One can also deploy a specific file by using their expected destination location as the make target.  For example, for deploying the specific file [`opt/cluster/bin/slurm/matlabXX`](opt/cluster/bin/slurm/matlabXX) to destination `/mnt/software/cluster/bin/slurm/matlabXX`, one can do

```bash
$ make PREFIX=/mnt/software DRYRUN=false /mnt/software/cluster/bin/slurm/matlabXX
```
