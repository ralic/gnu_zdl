#!/bin/bash
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
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

path_usr="/usr/local/share/zdl"

source $path_usr/libs/core.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/downloader_manager.sh
source $path_usr/libs/log.sh

[ -z "$background" ] && background=tty
source $path_usr/ui/widgets.sh

file_log="zdl_log.txt"
name_prog=ZigzagDownLoader

if [ -f "$file_log" ]
then
    log=1
fi

function start_timeout {
    local start=$(date +%s)
    local now
    local diff_now
    local max_seconds=60
    if [ -d /cygdrive ]
    then
	max_seconds=120
    fi
 
    
    touch "$path_tmp/irc-timeout"
    sed -r "/^${url_in//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
    
    for i in {0..12}
    do
	now=$(date +%s)
	diff_now=$(( now - start ))

	if grep -P "^$url_in$" "$path_tmp/irc-timeout" &>/dev/null
	then
	    exit

	elif (( diff_now >= $max_seconds ))
	then
	    touch "$path_tmp/${irc[nick]}"
	    sed -r "/^.+ ${url_in//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
	    kill_url "$url_in" 'xfer-pids'
	    kill_url "$url_in" 'irc-pids'
	    exit
	fi
		
	sleep 10
    done &
}

function set_mode {
    this_mode="$1"
    printf "%s $s\n" "$this_mode" "$url_in" >>"$path_tmp/irc_this_mode"
}

function get_mode {
    this_mode=$(grep "$url_in$" "$path_tmp/irc_this_mode" | cut -d' ' -f1)
    [ -z "$this_mode" ] && this_mode=stdout
}

function xdcc_cancel {
    # [ -z "$ctcp_src" ] &&
    # 	ctcp_src=$(grep "$url_in" "$path_tmp"/irc_xdcc 2>/dev/null |
    # 			  cut -d' ' -f1 | tail -n1)
    irc_send "PRIVMSG $ctcp_src" "XDCC CANCEL"
    irc_send "PRIVMSG $ctcp_src" "XDCC REMOVE"
    kill_url "$url_in" "xfer-pids"
}

function irc_quit {
    local pid_list
    touch "$path_tmp/${irc[nick]}"
    
    [ -f "$path_tmp/${file_in}_stdout.tmp" ] &&
	kill $(head -n1 "$path_tmp/${file_in}_stdout.tmp") 2>/dev/null

    xdcc_cancel
    exec 4>&-
    irc_send "QUIT"
    exec 3>&-

    #kill_url "$url_in" "irc-pids"
    
    if [ -d /cygdrive ]
    then
    	pid_list=( $(children_pids $PID) $PID )

    else
    	pid_list=( $(ps -o pid --no-headers --ppid $PID) $PID )
    fi

    for pid in ${pid_list[@]} 
    do
	kill -9 $pid
    done &

    exit 1
}

function irc_send {
    printf "%s\r\n" "$*" >&3
}


function irc_ctcp {
    local pre=$1
    local post=$2
    ## \015 -> \r ; \012 -> \n

    printf "%s :\001%s\001\015\012" "$pre" "$post" >&3
}

# function get_irc_code {
#     local msg="$1"
#     local code
#     #code=$(grep -h "$msg" $path_usr/irc/* |
# 		  # cut -d' ' -f1 |
# 		  #     head -n1) 
#     code=$(awk "/$msg/{print $1}" $path_usr/irc/*)
#     ## metodo alternativo (rivedere codifica dei file dei messaggi in $path_usr/irc/)
#     # [[ "$(cat $path_usr/irc/*)" =~ ([0-9]+)' "'[^\"]*$msg ]] &&
#     # 	code=${BASH_REMATCH[1]}

#     if [[ "$code" =~ ^[0-9]+$ ]]
#     then
# 	printf "%d" "$code"
# 	return 0

#     else
# 	return 1
#     fi
# }

# function get_irc_code {
#     local msg="$1"
#     local code
#     echo "$msg"
#     awk -v msg="$msg" '{match($0, /\"([^\"]+)\"/, pattern); if (match(msg, pattern[1])) {print pattern[1]}}' $path_usr/irc/*
# }

function check_notice {
    local chan
    notice="$1"
    notice2=${notice%%:*}
    notice2=${notice2%%','*}
    notice2=${notice2%%[0-9]*}
    notice2=${notice2%%SEND*}
    notice2=$(trim "$notice2")

    if [ "$errors_again" != "${errors_again//$notice2}" ]
    then
	_log 27
	irc_quit
    fi

    if [ "$errors_stop" != "${errors_stop//$notice2}" ]
    then
	_log 29
	irc_quit
    fi

    # if [[ "$notice" =~ 'JOIN #'([^\ ]+) ]]
    # then
    # 	chan="${BASH_REMATCH[1]}"
    # 	print_c 2 "/JOIN #${chan}"
    # 	irc_send "JOIN #${chan}"
    # fi
}

function check_ctcp {
    local irc_code key
    unset ctcp_msg ctcp_src

    ctcp_msg=( $(tr -d "\001\015\012" <<< "$*") )
    ctcp_src=$(grep "$url_in" "$path_tmp"/irc_xdcc 2>/dev/null |
		      cut -d' ' -f1 | tail -n1)

    
    ########### codice del msg: 
    # irc_code=$(get_irc_code "${ctcp_msg[*]}")
    # case $irc_code in
    # 	743|883|878|879|1124|1131)
    # 	    irc_quit
    # 	    ;;
    # esac

    if [ "${ctcp_msg[0]}" == 'DCC' ] &&
	   [ -n "$ctcp_src" ]
    then
	if [ "${ctcp_msg[1]}" == 'ACCEPT' ]
	then
	    print_c 1 "CTCP<< PRIVMSG $ctcp_src :${ctcp_msg[*]}"
	    set_resume
	
	elif [ "${ctcp_msg[1]}" == 'SEND' ]
	then
	    print_c 1 "CTCP<< PRIVMSG $ctcp_src :${ctcp_msg[*]}"
	    
	    ctcp[file]="${ctcp_msg[2]}"
	    ctcp[address]="${ctcp_msg[3]}"
	    ctcp[port]="${ctcp_msg[4]}"
	    ctcp[size]="${ctcp_msg[5]}"
	    ctcp[offset]=$(size_file "${ctcp[file]}")
	    [ -z "${ctcp[offset]}" ] && ctcp[offset]=0

	    if ctcp[address]=$(check_ip_xfer "${ctcp[address]}") &&
		    [[ "${ctcp[port]}" =~ ^[0-9]+$ ]]
	    then
		return 0
	    fi
	fi
    fi
    return 1
}

function set_resume {
    echo "$url_in" >>"$path_tmp"/irc_xdcc_resume
}

function get_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	grep -P "^$url_in$" "$path_tmp"/irc_xdcc_resume &>/dev/null
    fi
}

function init_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	sed -r "/^${url_in//\//\\/}$/d" -i "$path_tmp"/irc_xdcc_resume
    fi
}

function check_dcc_resume {
    if [ -f "${ctcp[file]}" ] &&
	   [ -f "${ctcp[file]}.zdl" ] &&
	   [ "$(cat "${ctcp[file]}.zdl")" == "$url_in" ] &&
	   (( ctcp[offset]<ctcp[size] ))
    then

	irc_ctcp "PRIVMSG $ctcp_src" "DCC RESUME ${ctcp[file]} ${ctcp[port]} ${ctcp[offset]}" >&3
	print_c 2 "CTCP>> PRIVMSG $ctcp_src :DCC RESUME ${ctcp[file]} ${ctcp[port]} ${ctcp[offset]}" 

	for ((i=0; i<10; i++))
	do		    
	    if [ -f "$path_tmp"/irc_xdcc_resume ] &&
		   get_resume
	    then
		init_resume
		return 0
	    fi
	    sleep 1
	done
    fi
    return 1
}

function check_ip_xfer {
    local ip_address="$1"

    if [[ "$ip_address" =~ ^[0-9]+$ ]]
    then
	ip_address=$(dotless2ip $ip_address)
	
    elif [[ "$ip_address" =~ ^[0-9a-zA-Z:]+$ ]]
    then
	ip_address="[$ip_address]"
    fi

    if [ -n "$ip_address" ]
    then
	printf "$ip_address"
	return 0

    else
	return 1
    fi
}

function dcc_xfer {
    local offset old_offset pid_cat
    unset resume

    check_dcc_resume && resume=true

    exec 4<>/dev/tcp/${ctcp[address]}/${ctcp[port]} &&
	{
	    if [ -n "$resume" ]
	    then
		unset resume
		cat <&4 >>"$file_in" &
		pid_cat=$!

	    else
		cat <&4 >"$file_in" &
		pid_cat=$!
	    fi
			
	    if [ -n "$pid_cat" ]
	    then
		print_c 1 "Connesso all'indirizzo: ${ctcp[address]}:${ctcp[port]}"
		set_mode "daemon"
		echo "$url_in"  >"$file_in.zdl"
		add_pid_url "$pid_cat" "$url_in" "xfer-pids"
					
		while [ ! -f "$path_tmp/${file_in}_stdout.tmp" ]
		do
		    sleep 0.1
		done
		sed -r "s,____PID_IN____,$pid_cat,g" -i "$path_tmp/${file_in}_stdout.tmp"
	    fi

	    this_mode=daemon
	    while [ ! -f "${file_in}" ]
	    do
		sleep 0.1
	    done

	    while check_pid "$pid_cat" && [ "$offset" != "${ctcp[size]}" ]
	    do
		[ -f "$path_tmp/irc-timeout" ] &&
		    ! grep -P "^$url_in$" "$path_tmp/irc-timeout" &>/dev/null &&
		    echo "$url_in" >>"$path_tmp/irc-timeout"
		
		offset=$(size_file "$file_in")
		[ -z "$offset" ] && offset=0
		[ -z "$old_offset" ] && old_offset=$offset
		(( old_offset > offset )) && old_offset=$offset
		
		printf "XDCC %s %s %s XDCC\n" "$offset" "$old_offset" "${ctcp[size]}" >>"$path_tmp/${file_in}_stdout.tmp"

		old_offset=$offset

		## (offset - old_offset /1024) KB/s --> sleep 1 (ogni secondo)
		sleep 1
	    done

	    if [ "$(size_file "$file_in")" == "${ctcp[size]}" ]
	    then
		rm -f "${file_in}.zdl"
		set_link - "$url_in"
	    fi

	    irc_quit
	}
}

function join_xdcc_send {
    local line="$1"
    local msg
    
    if [[ "$line" =~ (MODE ${irc[nick]}) ]] &&
	   [ -n "${irc[chan]}" ]
    then
	print_c 1 "$line"
	
	irc_send "JOIN #${irc[chan]}"
	print_c 2 ">> JOIN #${irc[chan]}"
    fi

    if [[ "$line" =~ (JOIN :) ]] &&
	   [ -n "${irc[msg]}" ]
    then
	unset irc[chan]
	
	print_c 1 "<< $line"

	read -r to msg <<< "${irc[msg]}"
	echo "$to $url_in" >>"$path_tmp"/irc_xdcc
	xdcc_cancel
	sleep 3
	irc_send "PRIVMSG $to" "$msg"
	print_c 2 ">> PRIVMSG $to :$msg"
	
	unset irc[msg]
    fi

    if [[ "$line" =~ 'Join #'([^\ ]+)' for !search' ]]
    then
	chan="${BASH_REMATCH[1]}"
    	print_c 2 ">> JOIN #${chan}"
    	irc_send "JOIN #${chan}"
    fi
}

function check_irc_command {
    local cmd="$1"
    local txt="$2"
    
    case "$cmd" in
	PING)
	    unset chunk
	    if [ -n "$txt" ]
	    then
		chunk=":$txt"

	    else
		chunk="${irc[nick]}"
	    fi
	    ## print_c 2 "PONG $chunk"
	    irc_send "PONG $chunk"
	    ;;
	NOTICE)
	    check_notice "$txt"
	    print_c 4 "<< $txt"
	    ;;
	PRIVMSG)
	    if check_ctcp "$txt"
	    then
		file_in="${ctcp[file]}"
		sanitize_file_in
		
		url_in_file="/dev/tcp/${ctcp[address]}/${ctcp[port]}"
		echo -e "$file_in\n$url_in_file" >"$path_tmp/${irc[nick]}"
		
		while [ ! -f "$path_tmp/${file_in}_stdout.tmp" ]
		do sleep 0.1
		done
		
		dcc_xfer &
		pid_xfer=$!			
		add_pid_url "$pid_xfer" "$url_in" "xfer-pids"
	    fi
	    ;;
    esac
}

function check_line_regex {
    local line="$1"

    if [[ "$line" =~ (${to//\|/\\\|}\ *:No such nick\/channel) ]]
    then
	notice="${BASH_REMATCH[1]}"
	_log 27
	irc_quit
    fi
}

function irc_client {
    local line user from txt irc_cmd
    
    if exec 3<>/dev/tcp/${irc[host]}/${irc[port]}
    then
	print_c 1 "host: ${irc[host]}\nchan: ${irc[chan]}\nmsg: ${irc[msg]}\nnick: ${irc[nick]}"
	
	irc_send "NICK ${irc[nick]}"
	irc_send "USER ${irc[nick]} localhost ${irc[host]} :${irc[nick]}"

	while read line
	do
	    get_mode

	    line=$(tr -d "\001\015\012" <<< "${line//\*}")

	    if [ "${line:0:1}" == ":" ]
	    then
		from="${line%% *}"
		line="${line#* }"
	    fi

	    # from="${from:1}"
	    # user=${from%%\!*}
	    txt=$(trim "${line#*:}")
	    irc_cmd="${line%% *}"

	    join_xdcc_send "$line"
	    
	    ## per ricerche e debug:
	    #print_c 3 "$line"

	    check_line_regex "$line"

	    check_irc_command "$irc_cmd" "$txt"


	done <&3
	irc_pid=$!
	add_pid_url "$irc_pid" "$url_in" "irc-pids"
	echo "$irc_pid" >>"$path_tmp/external-dl_pids.txt"

	return 0

    else
	return 1
    fi
}



################ main:
PID=$$
path_tmp=".zdl_tmp"

set_mode "stdout"
this_tty="$7"


#errors=$(grep -P '(743|883|878|879|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' $path_usr/irc/* -h) # |cut -d'"' -f2 |cut -d'%' -f1)

errors_again=$(grep -P '(743|883|890|891|1124|1131|1381|1382|1775|1776|1777|1778)' $path_usr/irc/* -h)
errors_stop=$(grep -P '(878|879)' $path_usr/irc/* -h)

declare -A ctcp
declare -A irc

irc=(
    [host]="$1"
    [port]="$2"
    [chan]="$3"
    [msg]="$4"
    [nick]="$5"
)

url_in="$6"
add_pid_url "$PID" "$url_in" "irc-pids"
start_timeout
init_resume
add_pid_url "$PID" "$url_in" "irc-client-pid"
exec 3>&-

irc_client ||
    {
	touch "$path_tmp/${irc[nick]}"
	_log 26
	exec 3>&-

	if [ -d /cygdrive ]
	then
	    kill -9 $(children_pids $PID)
	    
	else
	    kill -9 $(ps -o pid --no-headers --ppid $PID)
	fi
    }
