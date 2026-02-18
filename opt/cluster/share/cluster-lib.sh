#!/bin/bash
#
# Helper functions for cluster-* scripts

MENTAT_MACHINE_FILE=$CLUSTER_UTIL_ROOT/etc/machines.mentat
TORQUE_MACHINE_FILE=$CLUSTER_UTIL_ROOT/etc/machines.torque
LOCAL_MACHINE_FILE=~/machines
MACHINE_FILES="$LOCAL_MACHINE_FILE $MENTAT_MACHINE_FILE $TORQUE_MACHINE_FILE"

unset XDG_RUNTIME_DIR
unset XDG_SESSION_ID
unset XDG_DATA_DIRS

function echo_success() {
    echo -e "[\033[32m OK \033[0m]"
    return 0
}

function echo_failure() {
    echo -e "[\033[31m FAILED \033[0m]"
    return 0
}

function isSuperUser() {
    GRID=$(id -g "$(whoami)")

    if [ $GRID -eq 0 ] || [ $GRID -eq 601 ]; then
        echo 1
    else
        echo 0
    fi
}

function getRawReport()
{
	port=$1
	
	for machine in $MACHINES
	do
		# get load info from the machine
		report=`socket_client $machine $port 2> /dev/null`
		if [ "$report" == "" ]
		then
			echo $machine is not available >&2
		else
			# insert machine name and filter comma's out of the report
			echo $machine $report | sed 's/,//g'
		fi
	done
}

function randomline()
{
	inputfile=$1
	lines=`wc -l $inputfile | awk '{ print $1 }'`
	rndnumber=$RANDOM
	let "rndnumber %= $lines"
	let "rndnumber += 1"
	sed "${rndnumber}q;d" $1
}

function extramatlabs()
{
	extra_matlabs=/opt/cluster/.extra_matlabs
	highestmentatnumber=`cat /opt/cluster/machines  | tail -1 | sed 's/mentat//'`
	fromno=`expr $highestmentatnumber + 1`
	tono=500


	# add some dummy data ;-)
	for number in `seq $fromno $tono`
	do
		randomline $extra_matlabs | sed "s/QQQ/${number}/"
		usleep $(bc <<< "$RANDOM * 2")
	done
}


#---------------------------------------------------------------------#
# get_script_dir: resolve absolute directory in which the current     #
#                 script is located.                                  #
#---------------------------------------------------------------------#
function get_script_dir() {
    ## resolve the base directory of this executable
    local SOURCE=$1
    while [ -h "$SOURCE" ]; do
        # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"

        # if $SOURCE was a relative symlink,
        # we need to resolve it relative to the path
        # where the symlink file was located

        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done

    echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

#---------------------------------------------------------------------#
# module_loaded_version: gets the currently loaded version of a given #
#                        module.                                      #
#---------------------------------------------------------------------#
function module_loaded_version() {
    local app=$1
    module -t list 2>&1 | egrep "^${app}/" | sed "s|${app}/||g" | sort -r | head -n 1
}

#---------------------------------------------------------------------#
# module_default_version: gets the default version of a given module  #
#                         if it is specified by the .version file.    #
#---------------------------------------------------------------------#
function module_default_version() {
    local app=$1
    module -t avail ${app} 2>&1 | egrep "^${app}/" | grep '(default)' | sed "s|${app}/||g" | sed 's/(default)//g'
}

#---------------------------------------------------------------------#
# module_avail_versions: get a list of versions of a given module.    #
#                                                                     #
#    The output is reverse-sorted alphabetically with the currently   #
#    loaded or default version prepended with `^`.                    #
#                                                                     #
#    Versions are printed line-by-line.                               #
#---------------------------------------------------------------------#
function module_avail_versions() {
    local app=$1
    local loaded=$(module_loaded_version $app)
    local default=$(module_default_version $app)

    # set loaded as default
    [ "$loaded" != "" ] && default=$loaded

    module -t avail ${app} 2>&1 | egrep "^${app}/" | sed "s|${app}/||g" | sed 's/(default)//g' | sort -r | while read l; do
        # print out all available versions, excluding the default
        [ "$l" != "$default" ] && echo "${l}" || echo "^${l}"
    done
}

#---------------------------------------------------------------------#
# rem_walltime: calculate remaining hours/minutes until 8 pm          #
#---------------------------------------------------------------------#
function rem_walltime() {
    # Function to calculate the default walltime
    # This function calculates the remaining hours/minutes until
    # 20:00 (08 pm)
    # This is used as the default walltime for slurm if no walltime is
    # specified in the matlab startscript (matlabXX)...
    #
    # 07nov13 - edwger

    # Determine current time and specify end time (not 8pm but 7pm for
    # calculation purpose (hours left after calculating remaining hours)
    local now=$(date +"%k:%M")
    local stop="19:00"
    
    local hrs_now=$((echo $now) | awk -F : '{ print $1 }')
    local mins_now_1=$((echo $now) | awk -F : '{ print $2 }')

    # remove leading zeros
    mins_now="$(echo $mins_now_1 | sed 's/0*//')"

    # mins_now can be 00 and becomes empty if zeros are stripped, so...
    if [ -z $mins_now ]; then
        mins_now="0"
    fi

    local hrs_remain=""
    local mins_remain=""
    if [ "$hrs_now" -ge "20" -o "$hrs_now" -lt "8" ]; then
        # Default walltime is 4 hours between 8pm and 8am (night)
        hrs_remain="04"
        mins_remain="00"
    else
        # Calculate walltime between 8am until 8pm (day)
        hrs_remain=$[19 - $hrs_now]
        mins_remain=$[60 - $mins_now]

        # mins_remain can be 60 if mins_now is 0. When mins_remain
        # equals 60 it will be changed to 00 and hrs_remain will
        # be increased by 1
        if [ "$mins_remain" -eq "60" ]; then
            mins_remain="00"
            hrs_remain=$(($hrs_remain+1))
        fi
        
        # Change walltime to 4 hours if remaining hours are less
        # then 4 hours
        if [ "$hrs_remain" -lt "4" ]; then
            hrs_remain="04"
            mins_remain="00"
        fi
    fi

    # put remaining walltime in var
    echo "$hrs_remain:$mins_remain:00"
}

#---------------------------------------------------------------------#
# make_requirement: general interface to ask providing resource       #
#                          requiremnets.                              #
# The requirement string is stored as $RESRC_REQUIREMENT variable     #
#---------------------------------------------------------------------#
function make_requirement() {

    # default requirements
    local default_walltime=$1
    local default_mem=$2

    echo " "
    echo "Specify the required time as HH:MM:SS (default $default_walltime)"
    echo -n "Enter time (HH:MM:SS) or press enter for default: "
    read WALLTIME
    if [ -z "$WALLTIME" ]; then
        WALLTIME=$default_walltime
    fi

    echo " "
    echo "Specify the required memory as XXgb (default $default_mem)"
    echo -n "Enter memory (XXgb) or press enter for default: "
    read MEM

    if [ -z "$MEM" ]; then
       MEM=$default_mem
    fi

    while ! [[ $(echo $MEM | tail -3c | tr '[:upper:]' '[:lower:]') == "gb" ]]; do
        echo " "
        echo -n "Memory value needs to be specified with required "
        echo -e "\033[1mGB/gb\033[0m!"
        echo -n "Specify the required memory as XX"
        echo -ne "\033[1m\033[5mgb\033[0m!"
        echo " (default $default_mem)"
        echo -n "Enter memory (XXgb) or press enter for default: "
        read MEM;
        if [ -z "$MEM" ]; then
            MEM=$default_mem
        fi
    done

    # compose RESC_REQUIREMENT variable
    RESRC_REQUIREMENT="--time=$WALLTIME --mem=$MEM"
}

#---------------------------------------------------------------------#
# make_display: fix the DISPLAY variable for X11 applications         #
#---------------------------------------------------------------------#
function make_display() {

    # complete the DISPLAY with HOSTNAME
    if [ ${DISPLAY:0:1} == ":" ]; then
        # the display variable is formatted as :1.0, whereas the X11 output should go to mentat001:1.0
        DISPLAY=$HOSTNAME$DISPLAY
    fi

    # replace HOSTNAME by IP_ADDRESS as some GUI applications (e.g. LCModel) need it
    local h=`echo $DISPLAY | awk -F ':' '{print $1}'`
    local no_dp=`echo $DISPLAY | awk -F ':' '{print $2}'`
    local ip=`getent ahostsv4 $h | grep 'STREAM' | awk '{print $1}'`
    DISPLAY="${ip}:${no_dp}"

    # ensure that the display can be forwarded
    xhost + > /dev/null 2>&1
}

#---------------------------------------------------------------------#
# run_guiapp: general wrapper and interface for submitting            #
#             interactive GUI application to the cluster.             #
#---------------------------------------------------------------------#
function run_guiapp() {

    if [ $# -lt 2 ]; then
        echo "invalid number of arguments" 1>&2
        return 1
    fi

    local name_guiapp=$1
    local cmd_guiapp=$2
    local guimenu=$3
    local queue="interactive"

    #echo name_guiapp: $name_guiapp
    #echo cmd_guiapp:  $cmd_guiapp
    #echo guimenu:     $guimenu
    #echo partition:   $queue

    if [ $# -eq 4 ]; then
        queue=$4
    fi

    # allow setting default memory via the ${MEM} variable.
    [ -z $MEM ] && MEM=4

    if [[ $guimenu && ${guimenu-x} ]]
    then
        # use yad menu to specify requirements
        SELECTION=$(yad \
            --center \
            --ontop \
            --buttons-layout=center \
            --title="$name_guiapp JOB" \
            --text="Define Slurm Job Requirements:" \
            --text-align=center \
            --form \
            --separator=" " \
            --item-separator="," \
            --field="Enter walltime requirements in HH:MM:SS.\nDefault until 8PM:" \
            --field="Enter memory requirements in GB's.\nDefault ${MEM}GB:" \
            --field="":LBL \
            --field="Optional:":LBL \
            --field="Preserve job stdout/err:":CHK \
            --field="Run interactive session on specific slurm node...":LBL \
            --field="Nodename:" \
            "$(rem_walltime)" "${MEM}" "")
        ret=$?
        #echo $ret
        if [[ $ret -eq 1 ]] || [[ $ret -eq 252 ]]
        then
            echo "Command Cancelled"; exit 0
        fi
        IFS=' ' read -r -a REQUIREMENTS <<< $SELECTION
        WALLTIME=$(echo ${REQUIREMENTS[0]})
        MEM=$(echo ${REQUIREMENTS[1]}GB)
 	[ "${REQUIREMENTS[2]}" == "TRUE" ] && KEEPOE="-o %x.out-%j -e %x.err-%j" || KEEPOE="-o /dev/null -e /dev/null"
        NODENAME=$(echo ${REQUIREMENTS[3]})
        # compose RESC_REQUIREMENT variable
        RESRC_REQUIREMENT="--nodes=1 --ntasks-per-node=1 --x11 --mem=$MEM --time=$WALLTIME"
        if [ ! -z "$NODENAME" ]
        then
            #Run on an optional specific node
            #Always set short hostname first and add dccn.nl manually
            #echo ${NODENAME%%.*}
            RESRC_REQUIREMENT="--nodes=1 --ntasks-per-node=1 --x11 --mem=$MEM --time=$WALLTIME --nodelist=${NODENAME%%.*}"
            #echo $RESRC_REQUIREMENT
        fi

        # compose DISPLAY variable and make xhost setting
        make_display
    else

        echo " "
        echo "Scheduling an interactive $name_guiapp session for execution on slurm:"
        echo " "

        local hrs_now=$(date +"%k:%M" | awk -F : '{ print $1 }')
        local remaining_walltime=$( rem_walltime )

        if [ $hrs_now -lt 16 ] && [ $hrs_now -ge 8 ]; then
            echo "Default your job runs until 8pm."
        fi

        # compose RESRC_REQUIREMENT interactively
        make_requirement $remaining_walltime 6gb

        # compose DISPLAY variable and make xhost setting
        make_display
    fi

    moduletest=$(echo $cmd_guiapp | awk -F";" '{ print $2 }')
    $moduletest > /dev/null
    if [ $? -ne 0 ]; then
       mod=$(echo $moduletest | awk '{ print $3 }')
       echo
       echo "Module $mod only runs on Torque/Moab CentOS 7."
       exit
    fi

    echo
    echo -ne "\033[1mSubmitting job for interactive $name_guiapp session ... \033[0m"
    echo "srun -Q ${KEEPOE} --mail-type=FAIL --job-name=${name_guiapp} ${RESRC_REQUIREMENT} --partition=$queue bash -c \"ulimit -v unlimited && export DISPLAY=${DISPLAY} && ${CLUSTER_UTIL_ROOT}/bin/slurm/yadjobinfo-slurm && $cmd_guiapp\""
    echo

    srun -Q ${KEEPOE} --mail-type=FAIL --job-name=${name_guiapp} ${RESRC_REQUIREMENT} --partition=$queue bash -c "ulimit -v unlimited && export DISPLAY=${DISPLAY} && ${CLUSTER_UTIL_ROOT}/bin/slurm/yadjobinfo-slurm && $cmd_guiapp" &
}

#---------------------------------------------------------------------#
# run_app: general wrapper and interface for submitting               #
#          application to the cluster.                                #
#---------------------------------------------------------------------#
function run_app() {

    if [ $# -lt 2 ]; then
        echo "invalid number of arguments" 1>&2
        return 1
    fi

    local name_app=$1
    local cmd_app=$2
    local queue="batch"
    local mode="batch"
    echo name_app: $name_app
    echo cmd_app:  $cmd_app
    echo queue:    $queue
    echo mode:     $mode

    if [ $# -eq 3 ]; then
        queue=$3
        echo argument queue:$queue
    fi

    if [ $# -eq 4 ]; then
        queue=$3
        echo argument queue: $queue
        mode=$4
        echo argument mode:  $mode
    fi


    echo " "
    echo "Scheduling $name_app session for execution on slurm:"
    echo " "

    local hrs_now=$(date +"%k:%M" | awk -F : '{ print $1 }')
    local remaining_walltime=$( rem_walltime )

    if [ $hrs_now -lt 16 ] && [ $hrs_now -ge 8 ]; then
        echo "Default your job runs until 8pm."
    fi

    # compose RESRC_REQUIREMENT interactively
    make_requirement $remaining_walltime 6gb

    echo
    echo -ne "\033[1mSubmitting job for $name_app ... \033[0m"
    echo

    if [ "$mode" == "batch" ]; then
        jid_or_err=$( sbatch --job-name=$name_app ${RESRC_REQUIREMENT} --partition=$queue $cmd_app 2>&1 )
        ec=$?
 
        if [ $ec -eq 0 ]; then
            echo_success
            echo "$jid_or_err"
            echo 
            echo "Use squeue --job $(echo $jid_or_err | awk '{ print $4 }') to check status"
            echo 
        else
            echo_failure
            echo "error: $jid_or_err"
        fi
        echo
        return $ec
    else 
        echo $name_app
        #echo "srun -Q ${KEEPOE} --mail-type=FAIL --job-name=${name_app} ${RESRC_REQUIREMENT} --partition=$queue \"$cmd_app\""
	echo ${name_app}
	echo ${RESRC_REQUIREMENT}
	echo ${queue}
	echo ${cmd_app}
        srun -v --mail-type=FAIL --job-name=${name_app} --x11 ${RESRC_REQUIREMENT} --partition=${queue} ${cmd_app}
    fi
}
