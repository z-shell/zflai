# Copyright (c) 2018 Sebastian Gniazdowski

0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

if [[ ${zsh_loaded_plugins[-1]} != */zflai && -z ${fpath[(r)${0:h}]} ]]
then
    fpath+=( "${0:h}" )
fi

typeset -g ZFLAI_SRC_DIR=${0:h}

zmodload zsh/datetime
zmodload zsh/system
autoload -- .zflai-disk-jokey .zflai_check_start .zflai_learn_table .zflai_get_abstract_table_for \
            .zflai_read_ini_file .zflai_read_db_defs .zflai_read_table_defs \
            .zflai_store .zflai_sqlite_store .zflai_file_store .zflai_elasticsearch_store .zflai_mysql_store

typeset -g ZFLAI_FD=0 ZFLAI_NULL_FD=0 ZFLAI_LAST_ACTION="$EPOCHSECONDS" ZFLAI_KEEP_ALIVE=45 ZFLAI_STORE_INTERVAL=30

# Loads configuration from zstyle database into
# global variables, for direct and quicker access.
#
# No input, no return value (always true).
function zflai_refresh_config {
    builtin zstyle -s ":plugin:zflai:dj" keep_alive_time ZFLAI_KEEP_ALIVE || ZFLAI_KEEP_ALIVE=45
    builtin zstyle -s ":plugin:zflai:dj" store_interval ZFLAI_STORE_INTERVAL || ZFLAI_STORE_INTERVAL=30
    return 0
}

# Receives log message, sends it to in-memory
# log-keeper process.
#
# $1 - log message
function zflai-log {
    .zflai_check_start
    print -u $ZFLAI_FD -r -- "L $1"
    ZFLAI_LAST_ACTION="$EPOCHSECONDS"
}

# Creates a table? Or rather passes its
# definition to the dj
function zflai-ctable {
    local __line="$1"
    local -a match mbegin mend
    if [[ "$__line" = (#b)[[:blank:]]#"@"([^[:blank:]/]##)[[:blank:]]#/[[:blank:]]#([^[:blank:]:]##)[[:blank:]](#c0,1)([[:blank:]]#::[[:blank:]](#c0,1)|)(*) ]]; then
        :
    elif [[ "$__line" = (#b)[[:blank:]]#([^[:blank:]:]##)[[:blank:]](#c0,1)([[:blank:]]#::[[:blank:]](#c0,1)|)(*) ]]; then
        :
    else
        print "Improper zflai-ctable call, didn't recognize syntax"
        return 1
    fi
    .zflai_check_start
    print -u $ZFLAI_FD -r -- "T $1"
    ZFLAI_LAST_ACTION="$EPOCHSECONDS"
}

# Binary flock command that supports 0 second timeout (zsystem's
# flock in Zsh ver. < 5.3 doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere (tested on OS X,
# Linux, FreeBSD).
if [[ ! -e "${0:h}/myflock/flock" ]]; then
    (
        if zmodload zsh/system 2>/dev/null; then
            if zsystem flock -t 1 "${0:h}/myflock/LICENSE"; then
                echo "\033[1;35m""zdharma\033[0m/\033[1;33m""zsh-unique-id\033[0m is building small locking command for you..."
                make -C "${0:h}/myflock"
            fi
        else
            make -C "${0:h}/myflock"
        fi
    )
fi

# Initial read of configuration 
zflai_refresh_config

exec {ZFLAI_NULL_FD}>/dev/null

# vim:ft=zsh:et
