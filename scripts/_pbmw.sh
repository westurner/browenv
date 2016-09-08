#!/bin/bash

function _setup_pbm {
    #  $1 (str) -- PBM_PROFILEDIRNAME profile directory name string
    #               ($1 or "Profile 1")
    #  $2 (str) -- PBM_PROFILEPREFIX profile path prefix string
    #               ($2 or $_HOME or $HOME)
    #
    # see also: pbm -l (pbm/main.py#list_profile_bookmarks) 
    export PBM_PROFILEDIRNAME="${1:-${PBM_PROFILEDIRNAME:-"Default"}}"
    # local _HOME_USER="${_HOME:+"${_HOME}/${USER}"}"
    export PBM_PROFILEPREFIX="${2:-${HOME}}"
    export PBM_PROFILESDIR="${PBM_PROFILEPREFIX}"'/.config/google-chrome'
    export PBM_PROFILEPATH="${PBM_PROFILESDIR}"/"${PBM_PROFILEDIRNAME}" ;
    export PBM_BMARKS="${PBM_PROFILEPATH}"'/Bookmarks' ;

    export PBMWEB_HOST="${PBMWEB_HOST:-"localhost"}"
    export PBMWEB_PORT="${PBMWEB_PORT:-"28881"}"
    export PBMWEB_URL="http://${PBMWEB_HOST}:${PBMWEB_PORT}"
    export | grep 'PBM'
}

function pbmw {
    # pbmw()    -- run pbmw with ($1 or 'Profile 1') and ($2 or _HOME or HOME)
    #_setup_pbm "${@}"
    #shift; shift
    local pbm_bmarks="${1:-${PBM_BMARKS}}"
    pbm "${@}" "${pbm_bmarks}"
}


function pbmwebw {
    # pbmwebw() -- run pbmw with $1:bmarks $2:port $3:host
    #_setup_pbm "${@}"
    #shift; shift
    local pbm_bmarks="${1:-"${PBM_BMARKS}"}"
    local pbmweb_port="${2:-"${PBMWEB_PORT}"}"
    local pbmweb_host="${3:-"${PBMWEB_HOST:-"localhost"}"}"
    pbmweb -H "${pbmweb_host}" -P "${pbmweb_port}" \
        -f "${pbm_bmarks}" \
         --open-browser \
         -v
    #sleep 5 ; web "${PBM_URL}"
}

function pbmwebwopen {
    local url="${1:-${PBMWEB_URL}}"
    local web="$(which web)"
    if [[ "${web}" != "" ]]; then
        "${web}" "${url}"
    else
        for url in "${@}"; do 
            python -m webbrowser -t "${url}"
        done
    fi
}

function _setup_pbm_default {
    _setup_pbm "Default" "$HOME"
}

function pbmw_default {
    _setup_pbm_default
    pbmw "${@}"
    return
}

function pbmwebw_default {
    _setup_pbm_default
    pbmwebw "${@}"
    return
}

function pbmwebwopen_default {
    _setup_pbm_default
    pbmwebwopen "${@}"
    return
}

function _create_pbmw_symlinks {
    local scriptname='_pbmw.sh'
    local scriptnames=(
        "pbmw"
        "pbmw_default"
        "pbmwebw"
        "pbmwebw_default"
        "pbmwebwopen"
        "pbmwebwopen_default"
        "_pbmw-setup.sh"
    )
    for symlinkname in ${scriptnames[@]}; do
        test -L "${symlinkname}" && rm "${symlinkname}"
        ln -s "${scriptname}" "${symlinkname}"
    done
}

function pbmwhelp {
    # pbmwhelp()    -- pbm -h, pbmweb -h, list comments
    (set -x; pbm -h)
    (set -x; pbmweb -h)
    (cat "${BASH_SOURCE}" | \
        pyline.py -r '^\s*#+\s+.*' 'rgx and l')

    # TODO: pyline.py -n -f="${BASH_SOURCE}"
}

if [[ "${BASH_SOURCE}" == "${0}" ]]; then
    set -x
    declare -r progname="$(basename "${BASH_SOURCE}")"
    
    _setup_pbm "${@}"  # ${1:+"${1}"} ${2:+"${2}"}

    case "${progname}" in
        pbmw|pbmw.sh)
            pbmw "${@}"
            exit
            ;;
        pbmwebw|pbmwebw.sh)
            pbmwebw "${@}"
            exit
            ;;
        pbmwebwopen|pbmwebopen.sh)
            pbmwebwopen "${@}"
            exit
            ;;
        pbmw_default|pbmw_default.sh)
            pbmwebw_default "${@}"
            exit
            ;;
        pbmwebw_default|pbmwebw_default.sh)
            pbmwebw_default "${@}"
            exit
            ;;
        pbmwebwopen_default|pbmwebopen_default.sh)
            pbmwebwopen_default "${@}"
            exit
            ;;
        _pbmw.sh|*help|*help.sh)
            pbmwhelp
            exit
            ;;
        _pbmw-setup.sh)
            _create_pbmw_symlinks "${@}"
            exit
            ;;
        *)
            echo "Err"
            echo '${BASH_SOURCE}: '"'${BASH_SOURCE}'"
            echo '${progname}: '"'${BASH_SOURCE}'"
            echo ''
            pbmwhelp
            exit 2
            ;;
    esac
fi
