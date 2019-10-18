#!/bin/bash

#Include common stuff
CURRENT_DIR="$(dirname "$0")"
source $CURRENT_DIR/common.sh

main(){

	echo -e "\e[32mCreating nodes ... \e[39m"
	create_primary_node
	create_standby_node
	
	cat ${PRIMARY_DATA_DIR}.log
	#cat ${STANDBY_DATA_DIR}.log
}


create_primary_node(){

	echo "Creating primary data node ..."
	
	create_node_data_dir $PRIMARY_DATA_DIR
	update_port_and_socket_primary
	
	echo -e "\e[32mStarting server on port: \e[31m$PRIMARY_PORT\e[39m"
	$PG_BIN/pg_ctl -D $PRIMARY_DATA_DIR -l ${PRIMARY_DATA_DIR}.log start
	
	#Adding settings
	cmds=("CREATE ROLE ${REPL_USER} WITH REPLICATION PASSWORD '${REPL_USER}' LOGIN;" 
			"ALTER USER $DB_USER WITH PASSWORD '$DB_USER';"
			"SELECT * FROM pg_create_physical_replication_slot('${SLOT_NAME}');" 
			"ALTER system SET wal_level = hot_standby;"
			"ALTER system SET max_replication_slots = 3;"
			"ALTER system SET max_wal_senders = 3;")
	
	for query in "${cmds[@]}"
	do
		echo -e "\e[31mSending command: \e[32m${query}\e[39m"
		psql -h localhost -p $PRIMARY_PORT -U $DB_USER -c "${query}"
	done
	
	echo -e "\e[32mStopping server on port: \e[31m$PRIMARY_PORT\e[39m"
	$PG_BIN/pg_ctl -D $PRIMARY_DATA_DIR stop
}

create_standby_node(){
		
	$PG_BIN/pg_ctl -D $PRIMARY_DATA_DIR -l ${PRIMARY_DATA_DIR}.log start
	$PG_BIN/pg_basebackup -v -D $STANDBY_DATA_DIR -R -P -h localhost -p 5433 -U ${REPL_USER}
	
	$PG_BIN/pg_ctl -D $PRIMARY_DATA_DIR stop
	
	sed -i "s/^\(listen_addresses .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	sed -i "s/^\(port .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	sed -i "s/^\(unix_socket_directories .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	
	echo -e "\e[31mlisten_addresses = '*'\e[39m"
	echo "listen_addresses = '*'" >> $STANDBY_DATA_DIR/postgresql.conf
	echo "port = $SECONDARY_PORT" >> $STANDBY_DATA_DIR/postgresql.conf
	echo "unix_socket_directories = '`pwd`/$STANDBY_DATA_DIR'" >> $STANDBY_DATA_DIR/postgresql.conf
	echo "hot_standby = on" >> $PRIMARY_DATA_DIR/postgresql.conf
	echo "hot_standby_feedback = on" >> $PRIMARY_DATA_DIR/postgresql.conf
}

create_node_data_dir(){

	node_data_dir=$1
	$PG_BIN/initdb -U $DB_USER -D ${node_data_dir}
	echo -e "Changing permissions ..."
	chmod -R 700 $node_data_dir
}

update_port_and_socket_primary(){
		
	sed -i "s/^\(listen_addresses .*\)/# Commented out by Name YYYY-MM-DD \1/" $PRIMARY_DATA_DIR/postgresql.conf
	sed -i "s/^\(port .*\)/# Commented out by Name YYYY-MM-DD \1/" $PRIMARY_DATA_DIR/postgresql.conf
	sed -i "s/^\(unix_socket_directories .*\)/# Commented out by Name YYYY-MM-DD \1/" $PRIMARY_DATA_DIR/postgresql.conf
	
	
	echo "listen_addresses = '*'" >> $PRIMARY_DATA_DIR/postgresql.conf
	echo "port = $PRIMARY_PORT" >> $PRIMARY_DATA_DIR/postgresql.conf
	echo "unix_socket_directories = '`pwd`/$PRIMARY_DATA_DIR'" >> $PRIMARY_DATA_DIR/postgresql.conf
}


main "$@"
