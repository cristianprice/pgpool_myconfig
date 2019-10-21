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
	update_settings_primary
	
	echo -e "\e[32mStarting server on port: \e[31m$PRIMARY_PORT\e[39m"
	$PG_BIN/pg_ctl -w -D $PRIMARY_DATA_DIR -l ${PRIMARY_DATA_DIR}.log start
	
	#Adding settings
	cmds=("ALTER USER $DB_USER WITH PASSWORD '$DB_USER';"
			"SELECT * FROM pg_create_physical_replication_slot('${SLOT_NAME}');" 
		 )
	
	for query in "${cmds[@]}"
	do
		echo -e "\e[31mSending command: \e[32m${query}\e[39m"
		psql -h localhost -p $PRIMARY_PORT -U $DB_USER -c "${query}"
	done
	
	echo -e "\e[32mStopping server on port: \e[31m$PRIMARY_PORT\e[39m"
	$PG_BIN/pg_ctl -w -D $PRIMARY_DATA_DIR stop
}

create_standby_node(){
		
	$PG_BIN/pg_ctl -w -D $PRIMARY_DATA_DIR -l ${PRIMARY_DATA_DIR}.log start
	echo -e "\e[32m$PG_BIN/pg_basebackup -v -D $STANDBY_DATA_DIR -R -P -h localhost -p $PRIMARY_PORT -U $DB_USER\e[39m"
	$PG_BIN/pg_basebackup -v -D $STANDBY_DATA_DIR -R -P -h localhost -p $PRIMARY_PORT -U $DB_USER
	
	$PG_BIN/pg_ctl -w -D $PRIMARY_DATA_DIR stop
	
	sed -i "s/^\(listen_addresses .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	sed -i "s/^\(port .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	sed -i "s/^\(unix_socket_directories .*\)/# Commented out by Name YYYY-MM-DD \1/" $STANDBY_DATA_DIR/postgresql.conf
	
cat <<- EOF >> $STANDBY_DATA_DIR/postgresql.conf
	listen_addresses = '*'
	unix_socket_directories = '`pwd`/$STANDBY_DATA_DIR'
	port = $SECONDARY_PORT
EOF

}

create_node_data_dir(){

	node_data_dir=$1
	$PG_BIN/initdb -U $DB_USER -D ${node_data_dir}
	echo -e "Changing permissions ..."
	chmod -R 700 $node_data_dir
}

update_settings_primary(){

cat <<- EOF >> $PRIMARY_DATA_DIR/postgresql.conf
	listen_addresses = '*'
	unix_socket_directories = '`pwd`/$PRIMARY_DATA_DIR'
	port = $PRIMARY_PORT
    wal_level = hot_standby
    full_page_writes = on
    wal_log_hints = on
    max_wal_senders = 6
    max_replication_slots = 6
	
    hot_standby = on
    hot_standby_feedback = on
EOF

cat <<- EOF >> $PRIMARY_DATA_DIR/pg_hba.conf
    host all all 127.0.0.1/32 trust
	host replication $DB_USER 127.0.0.1/32 trust
	host replication all 127.0.0.1/32 trust
EOF

}


main "$@"
