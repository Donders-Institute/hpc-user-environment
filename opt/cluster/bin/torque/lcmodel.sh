#!/usr/bin/bash

# check if environment module is configured
use_local_mod=0
module list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    use_local_mod=1
    source /opt/_modules/setup.sh
    module load cluster
fi

# load helper functions
source $CLUSTER_UTIL_ROOT/share/cluster-lib.sh

# check if lcmodel is properly loaded 
module list 2>&1 | grep 'lcmodel' > /dev/null 2>&1
if [ $? -ne 0 ] || [ ! -d "${HOME}/.lcmodel/bin" ]; then
    module load lcmodel
fi

# parameters
## function to print usage
function print_usage() {

    cat <<EOF
Usage:

  $ lcmodel.sh -d <data_dir> [options]

  options:
    -d|--data_type <type>                     default: "siemens"
    -b|--basis_set <file>                     default: ""
    -c|--control   <file>                     default: ""
    -f|--data_file_filter <data file suffix>  default: ".rda"
    -o|--output_dir <output directory>        default: "\$PBS_O_DIR" or "\$PWD"
    -w|--water <water file suffix>            default: ""

EOF
}

## default parameters
DATA_FILE_FILTER=".rda"
DATA_TYPE="siemens"
OUTPUT_DIR=$PWD
if [ ! -z $PBS_O_DIR ]; then
    OUTPUT_DIR=$PBS_O_DIR
fi
#WATER="_h2o.rda"

## load user-specified parameters
while [[ $# > 1 ]]; do

    key="$1"

    case $key in
        -d|--data_dir)
        DATA_DIR="$2"
        shift # past argument
        ;;
        -b|--basis_set)
        FILBAS="$2"
        shift # past argument
        ;;
        -c|--control)
        CONTROL_TEMPLATE="$2"
        shift # past argument
        ;;
        -f|--data_file_filter)
        DATA_FILE_FILTER="$2"
        shift # past argument
        ;;
        -t|--data_type)
        DATA_TYPE="$2"
        shift # past argument
        ;;
        -o|--output_dir)
        OUTPUT_DIR="$2"
        shift # past argument
        ;;
        -w|--watar)
        WATER="$2"
        shift # past argument
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

## mandatory parameters
if [ -z $DATA_DIR ]; then
    print_usage
    exit 1
fi

## internal parameters
TEMP_DIR="/data/${UID}.$$/lcmodel"

if [ -z $FILBAS ]; then
    FILBAS="${LCMODEL_HOME}/basis/TrioPRESS30T30.BASIS"
fi

if [ "${DATA_TYPE}"  !=  "ge5"     -a \
     "${DATA_TYPE}"  !=  "gelx"    -a \
     "${DATA_TYPE}"  !=  "marconi" -a \
     "${DATA_TYPE}"  !=  "other"   -a \
     "${DATA_TYPE}"  !=  "philips" -a \
     "${DATA_TYPE}"  !=  "siemens" -a \
     "${DATA_TYPE}"  !=  "toshiba" ]
then
   echo "*** Illegal DATA_TYPE=${DATA_TYPE} ***"
   exit 1
fi

#check if lcmodel basis set exists
if [ ! -f "${FILBAS}" ]; then
   echo "Basis set \"${FILBAS}\" does not exist, exiting...";
   exit 1
fi

#check if argument is a directory and exists
if [ ! -d "${DATA_DIR}" ]; then
   echo "Directory \"${DATA_DIR}\" does not exist, exiting...";
   exit 1
fi

#check if control file template exists
if [ ! -f "${CONTROL_TEMPLATE}" ]; then
   echo "Control file template \"${CONTROL_TEMPLATE}\" does not exist, exiting...";
   exit 1
fi

cd  ${DATA_DIR}   # <------------ cd

echo "Changed to ${DATA_DIR}, "
echo "looking for SVS: *${DATA_FILE_FILTER} files."
#
for PATHNAME in *${DATA_FILE_FILTER}; do
   #check if it is really a file:
   if [ ! -f "${PATHNAME}" ]; then
        echo "No or no valid file: \"${PATHNAME}\"."
        continue
   fi

   echo "File SVS ${PATHNAME} seen..."
   PATID=$(echo ${PATHNAME} | sed -e "s/${DATA_FILE_FILTER}$//" )
   # check for the word "hippo" at the end; these are MRSI datasets! 
   if [[ ${PATID} =~ hippo$ ]]; then
        echo "Skipping MRSI file: \"${PATID}\"."
        continue
   fi

   # check if the single voxel spectroscopy is already processed:
   if [ -f ${PATID}.DONE ]; then
        echo "SVS analysis already done: \"${PATID}\"."
        continue
   fi

   mkdir  -p  ${TEMP_DIR}/${PATID}/met

   if [ -z $WATER ]; then
       mkdir  -p  ${TEMP_DIR}/${PATID}/h2o
   fi

   [ ! -d ${OUTPUT_DIR}/${PATID} ] && mkdir  -p  ${OUTPUT_DIR}/${PATID}

   #Read the data
   ${HOME}/.lcmodel/${DATA_TYPE}/bin2raw ${PATHNAME} ${TEMP_DIR}/${PATID}/ met
   if [ -z $WATER ]; then
       ${HOME}/.lcmodel/${DATA_TYPE}/bin2raw ${PATID}${WATER} ${TEMP_DIR}/${PATID}/ h2o
   fi

   echo "Now processing patient SVS \"${PATHNAME}\"..."

   ## composing control file for the PATID
   [ -f ${TEMP_DIR}/${PATID}/control ] && rm  -f  ${TEMP_DIR}/${PATID}/control
   echo " \$LCMODL" > ${TEMP_DIR}/${PATID}/control
   sed  -e '/^filps/d' -e 's/^/ /'  ${TEMP_DIR}/${PATID}/met/cpStart  >> ${TEMP_DIR}/${PATID}/control

   cat $CONTROL_TEMPLATE >> ${TEMP_DIR}/${PATID}/control 

   echo " savdir= '${OUTPUT_DIR}/'
 srcraw= '${DATA_DIR}/${PATHNAME}'
 filtab= '${TEMP_DIR}/${PATID}/${PATID}.table'
 filps= '${TEMP_DIR}/${PATID}/${PATID}.ps'
 filcoo= '${TEMP_DIR}/${PATID}/${PATID}.coord'
 filcsv= '${TEMP_DIR}/${PATID}/${PATID}.csv'
 filpri= '${TEMP_DIR}/${PATID}/${PATID}.print'
 filbas= '${FILBAS}'
 \$END" >> ${TEMP_DIR}/${PATID}/control

   # run lcmodel and save logs to runtime.log file
   [ -f ${TEMP_DIR}/${PATID}/${PATID}.runtime.log ] && rm -f ${TEMP_DIR}/${PATID}/${PATID}.runtime.log
   $HOME/.lcmodel/bin/lcmodel  <${TEMP_DIR}/${PATID}/control 2>>${TEMP_DIR}/${PATID}/${PATID}.runtime.log
   
   # copy and organise results into OUTPUT_DIR
   mv ${TEMP_DIR}/${PATID}/${PATID}* ${OUTPUT_DIR}/${PATID}/

   # clean up temporary directory 
   [ -d ${TEMP_DIR}/${PATID} ] && rm -rf ${TEMP_DIR}/${PATID}

   # mark the run on PATID is "DONE" 
   touch ${PATID}.DONE

done #end patient loop

echo "*** run-all-RDA-files completed. ***"
exit 0
