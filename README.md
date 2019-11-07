# Zflai – Fast-Logging Framework For Zshell

## Introduction

Adding logging to a script can constitute a problem – it makes the script run
slower. If the script is to perform some large work then increasing the
execution time by e.g.: 10-20% can lead to a significant difference.

Because of this, such large-work scripts are often limited to file-only logging,
because sending the messages to e.g.: `mysql` database would increase the
execution time even more.

### How Zflai Solves The Performance Issue

Zflai operates in the following way:

1. A background logging process is being started by a `>( … function …)`
   substitution.  
2. A file descriptor is remembered in the script process.
3. Writing to such descriptor is very fast.
4. An utility function `zflai-log` is provided, which sends the message to the
   background process through the descriptor.
5. The background process reads the data and remembers it in memory.
6. After each interval (configurable) it moves the data from the memory to one
   of supported backends:
   - file – a regular log file,
   - SQLite3,
   - MySQL,
   - ElasticSearch.
7. More, the background process shuts down itself after a configurable idle time
   (45 seconds by default). It is being automatically re-spawned by the
   `zflai-log` call whenever needed.
8. This means that `zflai` can be used e.g.: on all shells, as the number of
   processes will not be doubled – the background process will run only when
   needed, while the zero-lag logging will be continuously ready to use.

This way the script is slowed down by a minimum degree while a feature-rich
logging to databases like MySQL and ElasticSearch is being available.

## How To Use

There are only two end-user calls currently:

1. `zflai-ctable "{TABLE-NAME} :: {FIELD1}:{TYPE} / {FIELD2}:{TYPE}
   / … / {FIELDN}:{TYPE}"`

   The types are borrowed from SQL - they're `varchar(…)`, `integer`, etc.

   The function **defines a table**, which then, upon first use on given backend
   (e.g.: SQLite3 or ElasticSearch) will be created before storing the first
   data.

   The tables are not bound to any particular backend. They can be used with
   multiple backends or just one of them, etc.

2. `zflai-log "@{DB-NAME} / {TABLE} :: {FIELD1 TEXT…} | {FIELD2 TEXT…}
   | … | {FIELDN TEXT…}`

   Schedules the multi-column message for storage in database `DB-NAME`, in its
   table `TABLE`.

## The Backend (Database) Definitions

Zflai uses directory `~/.config/zflai` to keep the configuration files (or other
if the `$XDG_CONFIG_HOME` isn't `~/.config`). There, the `ini` files that define
the databases `@{DB-NAME}` from the `zflai-log` call are searched, under the
names `DB-NAME.def`. Below are example `ini` files for each of the supported
database backend.

### File Backend

```ini
; Contents of ~/.config/zflai/myfile.def
[access]
engine = file
file = %TABLE%.log
path = %XDG_CACHE_HOME%/zflai/

[hooks]
on_open = STATUS: Opening file %TABLE%.log
on_open_sh = print Hello world! >> ~/.cache/zflai/file_backend.nfo
on_close = STATUS: Closing file %TABLE%.log
on_close_sh = print Hello world! >> ~/.cache/zflai/file_backend.nfo

; vim:ft=dosini
```

Example file contents after:

```zsh
% zflai-ctable  "mytable :: timestamp:integer / message:varchar(288) / message2:varchar(20)"
% zflai-log "@myfile / mytable :: HELLO | WORLD"
```

are:

```zsh
% cat ~/.cache/zflai/mytable.log
STATUS: Opening file mytable.log
1572797669: HELLO WORLD
STATUS: Closing file mytable.log
```

### MySQL Backend

```ini
; Contents of ~/.config/zflai/mysql.def
[access]
engine = mysql
host = localhost
port =
user = root
password = …
database = test

[hooks]
on_open = !show databases;
on_open_sh = print -nr -- "$1" | egrep '(mysql|test)' >! ~/.cache/zflai/mysql.nfo
on_close = #show tables; select * from mytable;
on_close_sh = print -rl -- "$(date -R)" "$1" >>! %XDG_CACHE_HOME%/zflai/mysql.tables

; vim:ft=dosini
```

Example contents of the hook-created files after:

```zsh
% zflai-ctable  "mytable :: timestamp:integer / message:varchar(288) / message2:varchar(20)"
% zflai-log "@mysql / mytable :: HELLO | WORLD"
```

are:

```zsh
% cat ~/.cache/zflai/mysql.nfo
mysql
test
% cat ~/.cache/zflai/mysql.tables
Sun, 03 Nov 2019 17:55:56 +0100
mytable
1 1572800148 HELLO WORLD
```

Recognized `*_sh`-hook prefixes are:

- `#` – whitespace-collapse copying of the `mysql` command output,
- `!` - tokenize & newline – split into words and output separating by new lines,
- `@` - tokenize – split into words and output separating with spaces.

### SQLite3 Backend

```ini
; Contents of ~/.config/zflai/sqlite.def
[access]
engine = sqlite3
file = sqlite_main.db3
path = %XDG_CACHE_HOME%/zflai/

[hooks]
on_open = !.tables
on_open_sh = print -nr -- "$1" >! ~/.cache/zflai/sqlite.nfo
on_close = #select * from mytable;
on_close_sh = print -rl -- "$(date -R)" "$1" >>! %XDG_CACHE_HOME%/zflai/sqlite.tables

; vim:ft=dosini
```

Example contents of the hook-created files after:

```zsh
% zflai-ctable  "mytable :: timestamp:integer / message:varchar(288) / message2:varchar(20)"
% zflai-log "@sqlite / mytable :: HELLO | WORLD"
```

are:

```zsh
% cat ~/.cache/zflai/sqlite.nfo
mytable
% cat ~/.cache/zflai/sqlite.tables
Sun, 03 Nov 2019 18:14:30 +0100
1|1572801262|HELLO|WORLD
```

### ElasticSearch Backend

```ini
; Contents of ~/.config/zflai/esearch.def
[access]
engine = elastic-search
host = localhost:9200
index = my-db

; vim:ft=dosini
```

Example database contents after:

```zsh
% zflai-ctable  "mytable :: timestamp:integer / message:varchar(288) / message2:varchar(20)"
% zflai-log "@esearch / mytable :: HELLO | WORLD"
```

are:

```zsh
% curl -X GET "localhost:9200/my-db/_search" -H 'Content-Type: application/json
{
  "query": { "match_all": {} },
}' | jq '.hits.hits[]._source'

{
  "timestamp": "1573089118",
  "write_moment": "1573089124.9808938503",
  "message": "HELLO",
  "message2": "WORLD"
}
```

## Configuration

```zsh
# How long to keep dj running after last login request
zstyle ":plugin:zflai:dj" keep_alive_time 15

# Store to disk each 30 seconds
zstyle ":plugin:zflai:dj" store_interval 30
```

## Installation

Simply source or load as a Zsh plugin, e.g.: with Zplugin:

```zsh
zplugin load zdharma/zflai
```

or with zgen:

```zsh
zgen load zdharma/zflai
```

etc.

<!-- vim:set ft=markdown tw=80 fo+=an1 autoindent: -->
