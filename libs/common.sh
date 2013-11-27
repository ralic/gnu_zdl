#!/bin/bash -i
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

function check_pid {
    if [ ! -z $1 ]; then
	ck_pid=$1
	ps ax | awk "{ print $ps_ax_pid }" | while read ck_alive; do
	    if [ "$ck_alive" == "$ck_pid" ]; then
		return 1
	    fi
	done
    fi
}


function check_instance_prog {
    if [ -f "$path_tmp/pid.zdl" ]; then
	test_pid=`cat "$path_tmp/pid.zdl" 2>/dev/null`
	check_pid "$test_pid"
	if [ $? == 1 ]; then
	    pss=`ps ax|grep "$test_pid"`
	    max=`echo -e "$pss" | wc -l`
	    for line in `seq 1 $max`; do
		proc=`echo -e "$pss" |sed -n "${line}p"`
		pid=`echo "$proc" | awk "{ print $ps_ax_pid }"`
		tty=`echo "$proc" | awk "{ print $ps_ax_tty }"`
		if [ "$pid" == "${test_pid}" ] && [ "$pid" != "$pid_prog" ]; then
		    return 1
		fi
	    done
	fi
    fi
}


function clean_file {
    unset items
    if [ -f "$path_tmp/rewriting" ];then
	while [ -f "$path_tmp/rewriting" ]; do
	    sleeping 0.1
	done
    fi
    touch "$path_tmp/rewriting"
    if [ ! -z "$1" ] && [ -f "$1" ]; then
	file_to_ck="$1"
	last_line=`cat "$file_to_ck" |wc -l`
	for i in `seq 1 $last_line`; do
	    it=`cat "$file_to_ck" 2>/dev/null |sed -n "${i}p"`
	    
	    if [ "${items[*]}" == "${items[*]//$it}" ]; then
		items[${#items[*]}]=$it
	    fi
	done
	
	rm "$file_to_ck"
	
	for ij in ${items[*]}; do
	    [ ! -z "$ij" ] && echo "$ij" >> "$file_to_ck"
	done
    fi
    rm -f "$path_tmp/rewriting"
    unset items
}


function check_lock {
    test_lock=`ls "$path_tmp"/${prog}_lock_* 2>/dev/null`
    echo "lockfile=$lock_file"
    read -p "test=$test_lock"
    
    
    if [ ! -z "$test_lock" ]; then
	pid="${test_lock#*_lock_}"
	read -p "pid_test=$pid"
	check_pid $pid
	if [ $? == 1 ]; then
	    rm "$test_lock"
	    return 1
	fi
    else
	touch "$lock_file"
    fi
    touch "$lock_file"
}


function redirect_links {
    header_box "Links da processare"
    links="${links##\\n}"
    echo -e "${links//'\n'/\n\n}\n"
    separator "─"
    print_c 1 "\nLa gestione dei download è inoltrata a un'altra istanza attiva di $PROG (pid $test_pid), nel seguente terminale: $tty"
    rm -f "$path_tmp/lock.zdl\n"
    [ ! -z "$xterm_stop" ] && xterm_stop
    exit 1
}


function check_instance_daemon {
    test_instance=$( ps ax | grep "$prog" |grep "silent $PWD" )
    test_instance=${test_instance##* }
    if [ ! -z "$test_instance" ] && [ "$test_instance" != "$PWD" ]; then
	return 1
    else
	return 0
    fi
}

function char2code {
    char=$1
    char_code=$( printf "%d" "'$char" )
}

function code2char {
    code=$1
    code_char=$( printf \\$(printf "%03o" "$code" ))
}

function parse_int {
    int0="${1%% *}"
    base=$2
    int=$( echo $(( $base#${int0##0} )) ) #conversione di $int da base 36 a base decimale
}

function base36 {
        b36arr=( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
        for i in $(echo "obase=36; $1"| bc); do
            int="$int${b36arr[${i#0}]}"
        done
}
