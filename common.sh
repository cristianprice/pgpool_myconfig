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
REPL_USER=${REPL_USER:-"replication"}
PRIMARY_PORT=${PRIMARY_PORT:-5433}
SECONDARY_PORT=${SECONDARY_PORT:-5434}
SLOT_NAME=${SLOT_NAME:-"ph_slot_slave"}
PRIMARY_DATA_DIR=${PRIMARY_DATA_DIR:-"primary"}
STANDBY_DATA_DIR=${STANDBY_DATA_DIR:-"standby"}

echo
echo -e "\e[39m---------------------------------------------------"
echo -e "\e[39mPG_CONFIG: \e[32m$PG_CONFIG"
echo -e "\e[39mPG_BIN: \e[32m$PG_BIN"
echo -e "\e[39mDB_USER: \e[32m$DB_USER"
echo -e "\e[39mREPL_USER: \e[32m$REPL_USER"
echo -e "\e[39mPG_POOL: \e[32m$PG_POOL"
echo -e "\e[39mPRIMARY_PORT: \e[32m${PRIMARY_PORT}"
echo -e "\e[39mSECONDARY_PORT: \e[32m${SECONDARY_PORT}"
echo -e "\e[39mSLOT_NAME: \e[32m$SLOT_NAME"
echo -e "\e[39m---------------------------------------------------"
echo
