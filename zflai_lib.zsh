# Copyright (c) 2018 Sebastian Gniazdowski

# Allows only [a-zA-Z0-9] characters in input parameter name, outside
# of this range characters are replaced by "_${ord-code}_", e.g. _95_
# for the underline, `_'.
#
# $1 - the parameter name to moderate
# $2 - output parameter (its name) for the result
# $3 - prefix to be applied to the moderated param name

function .zflai_moderate_param_name {
    local __param_name="$1" __out_name="$2" __pfx="$3" __buf=""

    [[ -z "${__param_name}" || -z "${__out_name}" ]] && return 1

    integer len=${#__param_name} i
    for (( i = 1; i <= len; ++ i )); do
        if [[ "${__param_name[i]}" != [a-zA-Z0-9] ]]; then
            __buf+="_$(( ##${__param_name[i]} ))_"
        else
            __buf+="${__param_name[i]}"
        fi
    done

    : "${(P)__out_name::=${__pfx}${__buf}}"
    return 0
}

# Opposite to .zflai_moderate_param_name, decodes moderateed param name.
#
# $1 - the moderated parameter name to decode
# $2 - output parameter (its name) for the result
# $3 - prefix to remove from input or output parameter (the same effect,
#      implementation removes the prefix from input data)
function .zflai_original_param_name {
    local __tparam_name="$1" __out_name="$2" __pfx="$3" __buf="" ord

    __tparam_name="${__tparam_name#$__pfx}"

    integer len=${#__tparam_name}
    for (( i = 1; i <= len; ++ i )); do
        if [[ "${__tparam_name[i]}" = "_" ]]; then
            ord="${(M)__tparam_name[i+1,-1]##[0-9]##}"
            __buf+="${(#)ord}"
            (( i += ${#ord} + 1 ))
        else
            __buf+="${__tparam_name[i]}"
        fi
    done

    : "${(P)__out_name::=${__buf}}"
    return 0
}

# $1 - table name with possible %ID, %CN
# $2 - name of output parameter (default: REPLY)
function .zflai_resolve {
    local __table="$1" __var_name="${2:-REPLY}"
    __table="${__table//\%ID/$ZUID_ID}"
    __table="${__table//\%CN/$ZUID_CODENAME}"
    : "${(P)__var_name::=$__table}"
}

# $REPLY - formatted timestamp, for log
function .zflai_format_ts {
    builtin strftime -s ${1:-REPLY} '%Y%m%d-%H:%M:%S' "$EPOCHSECONDS"
}

function .zflai_subst_cmds {
    local buffer="$1" nul=$'\0'
    local -a cmds

    cmds=( ${(0)${(S)buffer//(#b)*\$\((?#)([^\\]\))/${match[1]}${match[2]%\)}${nul}}%$nul*} )

    [[ "${cmds[1]}" = "$buffer" ]] && { REPLY="$buffer"; return 0; }

    integer size="${#cmds}" i
    local -a outputs

    for (( i = 1; i <= size; ++ i )); do
        outputs[i]="$( ${(z)cmds[i]} )"
    done

    i=0
    REPLY="${(S)buffer//(#b)\$\((?#)([^\\]\))/${outputs[++i]}}"

    return 0
}

typeset -g ZFLAI_LIBS_SOURCED=1

# vim:ft=zsh:et:tw=72
