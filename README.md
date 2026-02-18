# Wrapper scripts and shared module files for HPC cluster

This repository contains wrapper scripts and shared module files located in the `/opt` directory on the DCCN HPC cluster.

## Development

Clone the repository to a local directory (e.g. `~/`):

```bash
$ git clone git@github.com:Donders-Institute/hpc-user-environment.git
$ cd hpc-user-environment
```

Create a new development branch before changing scripts (e.g. `bugfix-XYZ`):

```bash
$ git branch bugfix-XYZ
$ git checkout bugfix-XYZ
```

For testing a wrapper script in [`opt/cluster`](opt/cluster), one can run the script via the [test_run](test_run) script. It set the variables `$PATH` and `$CLUSTER_UTIL_ROOT` to ensure relevant files are loaded from the local development directory.  For example,

```bash
$ ./test_run opt/cluster/bin/slurm/sbash
```

After development test is successful, commit the branch to upstream (i.e. GitHub):

```bash
$ git push --set-upstream origin bugfix-XYZ
```

Go to the [GitHub repository page](https://github.com/Donders-Institute/hpc-user-environment) and make a new Pull Request (PR) for code review.

## Deployment

Files in the git repository are organized the same as they are deployed to their production destinations.  Use the [Makefile](Makefile) to copy them to the destination location.  E.g.

```bash
$ make
```

By default, it assumes `/mnt/software` as the top-level directory of the production destinations; and performs a dryrun. The top-level directory can be changed by `PREFIX` while the dryrun can be turned off by `DRYRUN=false`.  The command below will actually deploy files over into the production directory `/opt`.

```bash
$ make PREFIX=/opt DRYRUN=false
```

__NOTE:__

1. The [GUN make](https://www.gnu.org/software/make/) only deploy the file when the destination doesn't exist or the destination's last modification time is not later than the file in question.  One can force the deployment using the `-B` option of `make`.

1. One can also deploy a specific file by using their expected destination location as the make target.  For example, for deploying the specific file [`opt/cluster/bin/slurm/matlabXX`](opt/cluster/bin/slurm/matlabXX) to destination `/mnt/software/cluster/bin/slurm/matlabXX`, one can do

    ```bash
    $ make PREFIX=/mnt/software DRYRUN=false /mnt/software/cluster/bin/slurm/matlabXX
    ```
