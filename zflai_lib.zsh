# Copyright (c) 2018 Sebastian Gniazdowski

# Allows only [a-zA-Z0-9] characters in input parameter name, outside
# of this range characters are replaced by "_${ord-code}_", e.g. _95_
# for the underline, `_'.
#
# $1 - the parameter name to temper
# $2 - name of parameter to which to store the tempered name

function -zflai_temper_param_name {
    local __param_name="$1" __out_name="$2" __buf=""

    [[ -z "${__param_name}" || -z "${__out_name}" ]] && return 1

    len=${#__param_name}
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

# vim:ft=zsh:et:tw=72
