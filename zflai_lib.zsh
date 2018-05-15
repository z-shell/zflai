# Copyright (c) 2018 Sebastian Gniazdowski

# Allows only [a-zA-Z0-9] characters in input parameter name, outside
# of this range characters are replaced by "_${ord-code}_", e.g. _95_
# for the underline, `_'.
#
# $1 - the parameter name to moderate
# $2 - output parameter (its name) for the result

function -zflai_moderate_param_name {
    local __param_name="$1" __out_name="$2" __buf=""

    [[ -z "${__param_name}" || -z "${__out_name}" ]] && return 1

    integer len=${#__param_name}
    for (( i = 1; i <= len; ++ i )); do
        if [[ "${__param_name[i]}" != [a-zA-Z0-9] ]]; then
            __buf+="_$(( ##${__param_name[i]} ))_"
        else
            __buf+="${__param_name[i]}"
        fi
    done

    : "${(P)__out_name::=${__buf}}"
    return 0
}

# Opposite to -zflai_moderate_param_name, decodes moderateed param name.
#
# $1 - the moderated parameter name to decode
# $2 - output parameter (its name) for the result
function -zflai_original_param_name {
    local __tparam_name="$1" __out_name="$2" __buf="" ord

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

# vim:ft=zsh:et:tw=72
