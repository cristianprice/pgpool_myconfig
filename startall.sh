#!/bin/bash

#Include common stuff
CURRENT_DIR="$(dirname "$0")"
source $CURRENT_DIR/common.sh

$PG_BIN/pg_ctl -D $PRIMARY_DATA_DIR -l ${PRIMARY_DATA_DIR}.log start
$PG_BIN/pg_ctl -D $STANDBY_DATA_DIR -l ${STANDBY_DATA_DIR}.log start

tail -f ${PRIMARY_DATA_DIR}.log ${STANDBY_DATA_DIR}.log
