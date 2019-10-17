#!/bin/bash

# Get the pg_config of the system
PG_CONFIG=${PG_CONFIG:-`which pg_config`}
if [ -z "$PG_CONFIG" ]
then
	return -1
fi

PG_BIN=${PG_BIN:-`$PG_CONFIG --bindir`}
PG_POOL=${PG_POOL:-`which pgpool`}
DB_USER=${DB_USER:-"postgres"}
NODE_COUNT=${NODE_COUNT:-2}
START_PORT=${START_PORT:-5432}

echo
echo "---------------------------------------------------"
echo "DB_USER: $DB_USER"
echo "PG_POOL: $PG_POOL"
echo "PG_BIN: $PG_BIN"
echo "NODE_COUNT: ${NODE_COUNT}"
echo "---------------------------------------------------"
echo

main(){

	echo "Creating nodes ... "
	for (( c=0; c<${NODE_COUNT}; c++ ))
	do  
	   create_node $c `expr $START_PORT + $c`
	   update_data_dirs $c `expr $START_PORT + $c`
	done
	
	cat data*.log
}


create_node(){

	node_data_dir="data${1}"
	node_port=$2

	echo "Creating node data : ${node_data_dir} port: `expr $node_port + 1`"
	$PG_BIN/initdb -U $DB_USER -D ${node_data_dir}
	echo "Changing permissions ..."
	chmod -R 700 $node_data_dir
}

update_data_dirs(){
	node_data_dir="data${1}"
	node_port=$2

	echo "Updating data dirs ... "
	$PG_BIN/pg_ctl -D $node_data_dir -l $node_data_dir.log start
	queries=("alter system set port = $node_port")
	
	for query in queries
	do
		psql -U $DB_USER -c "$query"
	done
	
	$PG_BIN/pg_ctl -D $node_data_dir stop
}


main "$@"
