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
		port=`expr $START_PORT + $c`
	   create_node $c $port
	   update_port_and_socket_dir $c $port
	   update_data_dirs $c $port
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
	
	cmds=("CREATE ROLE replication WITH REPLICATION PASSWORD 'replication' LOGIN;" 
			"ALTER USER $DB_USER WITH PASSWORD '$DB_USER';")
		
	for query in "${cmds[@]}"
	do
		echo "Sending command: ${query}"
		psql -h localhost -p $node_port -U $DB_USER -c "${query}"
	done
	
	$PG_BIN/pg_ctl -D $node_data_dir stop
}

update_port_and_socket_dir(){
	node_data_dir="data${1}"
	node_port=$2
	
	sed -i "s/^\(listen_addresses .*\)/# Commented out by Name YYYY-MM-DD \1/" $node_data_dir/postgresql.conf
	sed -i "s/^\(port .*\)/# Commented out by Name YYYY-MM-DD \1/" $node_data_dir/postgresql.conf
	sed -i "s/^\(unix_socket_directories .*\)/# Commented out by Name YYYY-MM-DD \1/" $node_data_dir/postgresql.conf
	
	
	echo "listen_addresses = '*'" >> $node_data_dir/postgresql.conf
	echo "port = $node_port" >> $node_data_dir/postgresql.conf
	echo "unix_socket_directories = '`pwd`/$node_data_dir'" >> $node_data_dir/postgresql.conf
}

main "$@"
