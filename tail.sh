#!/bin/bash

#Include common stuff
CURRENT_DIR="$(dirname "$0")"
source $CURRENT_DIR/common.sh

tail -f ${PRIMARY_DATA_DIR}.log ${STANDBY_DATA_DIR}.log
