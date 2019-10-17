#!/bin/bash

# Get the pg_config of the system
PG_CONFIG=${PG_CONFIG:-`which pg_config`}
if [ -z "$PG_CONFIG" ]
then
	return -1
fi

PG_BIN=${PG_BIN:-`$PG_CONFIG --bindir`}

for data_dir in *; do
    if [ -d "$data_dir" ]; then
	echo "Starting $data_dir ..."
		$PG_BIN/pg_ctl -D $data_dir -l $data_dir.log start
    fi
done


