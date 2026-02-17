#!/bin/bash

function usage() {
    cat << EOF
Usage:
    $0 <convmv_ofile_list> [qsub_args]

EOF
}

ask() {
  local 'args' 'char' 'charcount' 'prompt' 'reply' 'silent'

  # Basic arguments parsing
  while [[ "${1++}" ]]; do
    case "${1}" in
      ( '--silent' | '-s' )
        silent='yes'
        ;;
      ( '--' )
        args+=( "${@:2}" )
        break
        ;;
      ( * )
        args+=( "${1}" )
        ;;
    esac
    shift || break
  done

  if [[ "${silent}" == 'yes' ]]; then
    for prompt in "${args[@]}"; do
      charcount='0'
      prompt="${prompt}: "
      reply=''
      while IFS='' read -n '1' -p "${prompt}" -r -s 'char'; do
        case "${char}" in
          # Handles NULL
          ( $'\000' )
            break
            ;;
          # Handles BACKSPACE and DELETE
          ( $'\010' | $'\177' )
            if (( charcount > 0 )); then
              prompt=$'\b \b'
              reply="${reply%?}"
              (( charcount-- ))
            else
              prompt=''
            fi
            ;;
          ( * )
            prompt='*'
            reply+="${char}"
            (( charcount++ ))
            ;;
        esac
      done
      printf '\n' >&2
      printf '%s\n' "${reply}"
    done
  else
    for prompt in "${args[@]}"; do
      IFS='' read -p "${prompt}: " -r 'reply'
      printf '%s\n' "${reply}"
    done
  fi
}

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

[ $# -lt 1 ] && usage && exit 1

qsub_args=${@:2}

[ ! -f $1 ] && echo "file not found: $1" 1>&2 && exit 2

if [ ! -f ~/.pass ]; then
    # prepare ~/.pass file for running SUDO in batch job
    pass=$(ask -s "SUDO password")
    echo "$pass" > ~/.pass && chmod 600 ~/.pass
fi
dir=$(get_script_dir $0)

cat $1 | while read l; do
    echo -n "submitting fix_utf8 job for $l ... "
    jname=$(basename $l | awk -F '.' '{print $1"."$2}')
    echo "$dir/fix_utf8.sh '$l'" | qsub -N ${jname}_fix ${qsub_args}
done
