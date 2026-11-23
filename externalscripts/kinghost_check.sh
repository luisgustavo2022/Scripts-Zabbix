#!/bin/bash
SCRIPT_DIR="/usr/lib/zabbix/externalscripts"
RESULT=$(python3 $SCRIPT_DIR/kinghost_monitor.py | grep "^$1:" | cut -d: -f2)
echo $RESULT
