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

function data_stdout {
    unset list file_stdout file_out alias_file_out url_out downloader_out pid_out length_out progress speed type_speed num_speed num_percent percent
    if [ ! -z "$1" ];then 
	list="$1"
    else
	list=`ls -1 "$path_tmp"/*_stdout.tmp 2>/dev/null`
    fi
    if [ ! -z "$list" ]; then
	export LANG="$prog_lang"
	export LANGUAGE="$prog_lang"
	i=0
	for item in $list; do
	    
	    file_stdout=$item
	    test_found=`cat "$file_stdout" 2>/dev/null |grep "404: Not Found"`
	    if [ -z "$test_found" ]; then
		test_found=`cat "$file_stdout" 2>/dev/null |grep "404 Not Found"`
	    fi
	    
	    if [ ! -z "$test_found" ]; then
		_log 3
		if [ ! -f "${file_in}.st" ]; then
		    rm -f "$file_stdout" "$file_in"
		fi
	    else
		pid_out[$i]=`head -n 1 $file_stdout 2>/dev/null` 
		
		url_out[$i]=`cat $file_stdout 2>/dev/null |grep "link_$prog"`
		url_out[$i]="${url_out[$i]#link_${prog}: }"
		
		downloader_out[$i]=`head -n 3 $file_stdout 2>/dev/null |sed -n '3p'`
		pid_prog_out[$i]=`head -n 4 $file_stdout 2>/dev/null |sed -n '4p'`
		
		progress_data=`tail "$file_stdout" 2>/dev/null |grep K |grep % |tail -n 1`
		progress_data="${progress_data//'..........'}"
		progress_data="${progress_data//[\[\]]}"
		file_o="${file_stdout//_stdout.tmp}"
		file_o="${file_o#$path_tmp/}"
		if [ "${downloader_out[$i]}" == "Wget" ]; then
		    length_out[$i]=`head -n 5 $file_stdout 2>/dev/null |sed -n '5p'|grep "length_in="`
		    length_out[$i]="${length_out[$i]#length_in=}"
		    if [ -z "${length_out[$i]}" ];then
			length_out[$i]=`cat $file_stdout 2>/dev/null |grep "Length:" |tail -n 1`
			length_out[$i]="${length_out[$i]#*Length: }"
			length_out[$i]="${length_out[$i]%%' '*}"
		    fi
		    
		    file_out[$i]=`cat "$file_stdout" 2>/dev/null |grep "Saving to"`
		    file_out[$i]="${file_out[$i]#*Saving to: \`}"
		    file_out[$i]="${file_out[$i]%\'*}"
		    if [ ! -z "${file_o}" ]; then
			file_out[$i]="$file_o"
		    fi
		    
		    if [ -z "${file_out[$i]}" ]; then
			file_out[$i]="$file_o"
		    fi
		    
		    if [ "${file_out[$i]}" != "${file_out[$i]%.alias}" ];then
			alias_file_out[$i]="${file_out[$i]}"
			file_out[$i]=`cat $file_stdout 2>/dev/null |grep filename`
			file_out[$i]="${file_out[$i]#*filename=\"}"
			file_out[$i]="${file_out[$i]%\"*}"
			file_stdout="$path_tmp/${alias_file_out[$i]}_stdout.tmp"
		    fi
		    
		    percent=`echo $progress_data | awk '{ print($2) }'`
		    eta=`echo $progress_data | awk '{ print($4) }'`
		    speed=`echo $progress_data | awk '{ print($3) }'`
		    speed="${speed//,/.}"
		    type_speed[$i]="${speed//[0-9.,]}"
		    num_speed[$i]="${speed//${type_speed[$i]}}"
		    num_speed[$i]=${num_speed[$i]%.*}
		    case ${type_speed[$i]} in
			B) type_speed[$i]="B/s";;
			K) type_speed[$i]="KB/s";;
			M) type_speed[$i]="MB/s";;
		    esac
		    speed="${num_speed[$i]}${type_speed[$i]}"
		    num_percent[$i]=0
		    num_percent[$i]=${percent%'%'*}
		    num_percent[$i]=${num_percent[$i]%'.'*}

		elif [ "${downloader_out[$i]}" == "Axel" ]; then
		    axel_parts_out[$i]=`head -n 5 $file_stdout 2>/dev/null |sed -n '5p'`
		    file_out[$i]=`cat "$file_stdout" 2>/dev/null |grep "Opening output file"`
		    file_out[$i]="${file_out[$i]#*Opening output file }"
		    
		    if [ ! -z "${file_out[$i]}" ] && [ "$file_o" != "${file_out[$i]}" ]; then
			print_c 3 "Errore nei dati: il file $file_stdout contiene i dati di ${file_out[$i]}"
			echo "$file_o != ${file_out[$i]}"
			exit 1
		    fi
		    
		    if [ -z "${file_out[$i]}" ]; then
			file_out[$i]="$file_o"
		    fi
		    
		    length_out[$i]=`cat "$file_stdout" 2>/dev/null |grep 'File size'` 
		    length_out[$i]="${length_out[$i]#*File size: }"
		    length_out[$i]="${length_out[$i]%% *}"
		    unset speed	
		    speed=`echo "$progress_data" | awk '{ print($2) }'`
		    type_speed[$i]="${speed//[0-9.,]}"
		    num_speed[$i]="${speed//${type_speed[$i]}}"
		    if [ -z "${num_speed[$i]//[0-9,.]}" ] && [ ! -z "${num_speed[$i]//.}" ]; then
			num_speed[$i]=$(( ${num_speed[$i]%[,.]*} + 1 ))
		    else
			num_speed[$i]=0
		    fi
		    case ${type_speed[$i]} in
			KB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 )) ;;
			MB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 * 1024 )) ;;
		    esac
		    unset percent
		    percent=`echo "$progress_data" | awk '{ print($1) }'`
		    if [ ! -z "${percent}" ]; then
			num_percent[$i]=${percent%'%'*}
			num_percent[$i]=$(( ${num_percent[$i]%[,.]*}+1 ))
			yellow_num_percent[$i]=${num_percent[$i]}
		    elif [ -f "${file_out[$i]}" ];then
			num_percent[$i]=${yellow_num_percent[$i]}
		    else
			num_percent[$i]=0
		    fi
		    if [ ! -z "${length_out[$i]}" ] && [ ! -z "${num_percent[$i]}" ]; then
			diff_length=$(( ${length_out[$i]} * (100 - ${num_percent[$i]}) / 100 ))
			diff_length=$(( ${diff_length%[,.]*}+1 ))
		    fi
		    if [ ! -z "${num_speed[$i]}" ] && [ ${num_speed[$i]} != 0 ]; then
			unset seconds minutes hours
			seconds=$(( $diff_length/${num_speed[$i]} ))
		    fi
		    if [ ! -z "$seconds" ]; then
			minutes=$(( $seconds/60 ))
			hours=$(( $minutes/60 ))
			minutes=$(( $minutes-($hours*60) ))
			eta[$i]="${hours}h${minutes}m"
		    else
			eta[$i]=""
		    fi
		fi
		length_saved[$i]=0
		[ -f "${file_out[$i]}" ] && length_saved[$i]=$(ls -l "./${file_out[$i]}" | awk '{ print($5) }')
		(( i++ ))
	    fi
	done
	export LANG="$user_lang"
	export LANGUAGE="$user_language"
	return 1
    fi
}


function data_alive {
    unset pid_alive pid_prog_alive file_alive downloader_alive alias_file_alive url_alive progress_alive length_alive alive
    data_stdout
    if [ $? == 1 ]; then
	client=1
	tot=$(( ${#pid_out[*]}-1 ))
	j=0
	for i in `seq 0 $tot`; do
	    check_pid ${pid_out[$i]}
	    if [ $? == 1 ]; then
		pid_alive[$j]="${pid_out[$i]}"
		pid_prog_alive[$j]="${pid_prog_out[$i]}"
		file_alive[$j]="${file_out[$i]}"
		downloader_alive[$j]="${downloader_out[$i]}"
		alias_file_alive[$j]="${alias_file_out[$i]}"
		url_alive[$j]="${url_out[$i]}"
		progress_alive[$j]="${progress_out[$i]}"
		length_alive[$j]=${length_out[$i]}
		alive=1
		(( j++ ))
		
	    fi
	done
    fi
}


function check_download {
    data_stdout
    if [ $? == 1 ]; then
	last_stdout=$(( ${#pid_out[*]}-1 ))
	for i in `seq 0 $last_stdout`; do
	    if [ "${file_in}" == "${file_out[$i]}" ] && [ ! -z "${length_saved[$i]}" ] && [ "$test_saved" != "${length_saved[$i]}" ]; then
		unset test_saved
		return 1
	    elif [ "${file_in}" == "${file_out[$i]}" ]; then
		test_saved="${length_saved[$i]}"
		break
	    fi
	done
    fi
}


function check_stdout {
    unset checked
    data_stdout
    if [ $? == 1 ]; then
	last_stdout=$(( ${#pid_out[*]}-1 ))
	for ck in `seq 0 $last_stdout`; do
	    
	    
	    check_pid ${pid_out[$ck]}
	    if [ $? == 1 ]; then
		if [ -f "${file_out[$ck]}" ] && [ -f "${alias_file_out[$ck]}" ]; then
		    rm -f "${alias_file_out[$ck]}"
		fi
		
		test_repeated="${repeated[${pid_out[$ck]}]}"
		repeated[${pid_out[$ck]}]=`tail -n 100 "$path_tmp/${file_out[$ck]}_stdout.tmp"`
		if [ "$test_repeated" ==  "${repeated[${pid_out[$ck]}]}" ] && [ -f "${file_out[$ck]}.st" ]; then
		    kill ${pid_out[$ck]}
		fi
		
		
		if [ ! -f "${file_out[$ck]}" ] && [ ! -f "${alias_file_out[$ck]}" ]; then
		    kill ${pid_out[$ck]}
		fi
	    fi
	    
	    check_pid ${pid_out[$ck]}
	    if [ $? != 1 ]; then
		length_saved=0
		[ -f "${file_out[$ck]}" ] && length_saved=`ls -l "./${file_out[$ck]}" | awk '{ print($5) }'`
		
		already_there=`cat "$path_tmp/${file_out[$ck]}_stdout.tmp" 2>/dev/null |grep 'already there; not retrieving.'`
		if [ -z "$already_there" ]; then 
		    unset already_there
		    
		    if [ "${length_out[$ck]}" == "0" ] || ( [ ! -z "${length_out[$ck]}" ] && (( ${length_out[$ck]} > 0 )) && (( $length_saved < ${length_out[$ck]} )) ); then
			[ ! -f "${file_out[$ck]}.st" ] && rm -f "${file_out[$ck]}"
		    fi
		    if ( [ ! -z "${length_out[$ck]}" ] && [ "${length_out[$ck]}" != "0" ] && (( "$length_saved" == "${length_out[$ck]}" )) && (( ${length_out[$ck]} > 0 )) ); then 
			[ ! -f "${file_out[$ck]}.st" ] && links_loop - "${url_out[$ck]}"
		    fi

		else ## file exists: don't loop its url_out

		    print_c 3 "Errore: "$path_tmp"/${file_out[$ck]}_stdout.tmp  --> \"already there; not retrieving.\": $PROG ha cercato di scaricare di nuovo un file già esistente nella directory di destinazione"
		    read -p "ATTENZIONE!"
		    rm -f "$path_tmp/${file_out[$ck]}_stdout.tmp"

		fi
		
	    fi
	done
	return 1
    fi
}

function check_alias {
	## if file_in is an alias...
    
    if [ -f "$file_in" ] && [ -f "$path_tmp/${file_in}_stdout.tmp" ] && [ "${file_in}" != "${file_in%.alias}" ]; then
	data_stdout
	if [ $? == 1 ]; then
	    last_stdout=$(( ${#pid_out[*]}-1 ))
			#read -p ${#pid_out[*]}
	    for i in `seq 0 $last_stdout`; do
		check_pid ${pid_out[$i]}
		if [ $? == 1 ]; then
		    check_pid ${pid_in}
		    if [ $? == 1 ]; then
			unset real_file_in 
			real_file_in=`cat "$path_tmp"/${file_in}_stdout.tmp |grep filename`
			real_file_in="${real_file_in#*filename=\"}"
			real_file_in="${real_file_in%\"*}"
			
			file_in_alias="${file_in}"
			file_in="${real_file_in}"
			
			if [ "${pid_out[$i]}" != "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			    kill $pid_in
			    rm -f  "${file_in_alias}"
			elif [ "${pid_out[$i]}" == "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			    check_in_file    ## se file_in esiste, ne verifica la validità --> potrebbe cancellarlo
			    if [ ! -f "$file_in" ]; then
				mv "$file_in_alias" "$file_in"
				print_c 1 "$file_in_alias rinominato come $file_in"
			    else
				kill $pid_in
				rm -f  "${file_in_alias}"
			    fi
			fi
		    fi
		    
		    check_pid ${pid_in}
		    if [ $? != 1 ] && [ "${pid_out[$i]}" != "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			rm -f "${file_in}"
		    fi
		fi
	    done
	fi
    fi
}

function pipe_files {
    for i in $(seq 0 ${#file_out[*]}); do
	if [ ! -z ${length_out[$i]} ]; then
	    if [ "${downloader_out[$i]}" == "Axel" ]; then
		denum=$(( $axel_parts*100 ))
	    else
		denum=100
	    fi
	    [ -z ${num_percent[$i]} ] && num_percent[$i]=0
	    length_down=$(( ${length_out[$i]}*${num_percent[$i]}/$denum ))
	    case ${type_speed[$i]} in
		KB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 )) ;;
		MB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 * 1024 )) ;;
	    esac
	    if [ -f "${file_out[$i]}" ] && ( (( "$length_down">5000000 )) && (( ${num_speed[$i]}>200000 )) ) || ( ((  "${length_saved[$i]}" == ${length_out[$i]} )) && [ ! -f "${file_out[$i]}.st" ] ); then
		if [ -z $(cat "$path_tmp"/pipe_files.txt 2>/dev/null | grep "${file_out[$i]}") ]; then
		    echo "${file_out[$i]}" >> "$path_tmp"/pipe_files.txt
		fi
	    else
		listpipe=$(cat "$path_tmp"/pipe_files.txt 2>/dev/null)
		listpipe="${listpipe//${file_out[$i]}}"
		echo -e "$listpipe" > "$path_tmp"/pipe_files.txt
	    fi
	fi
    done
    _out
}


function _out {
    if [ -f "$path_tmp"/pipe_files.txt ]; then
	[ -f "$path_tmp"/pid_pipe ] && [ -z "$pid_pipe_out" ] && pid_pipe_out=$(cat "$path_tmp"/pid_pipe)
	check_pid $pid_pipe_out
	test=$?
	if [ ! -z "$pipe_out" ] && [ "$test" != 1 ]; then
	    outfiles=( $(cat "$path_tmp"/pipe_files.txt) )
	    if [ ! -z "${outfiles[*]}" ]; then
		nohup $pipe_out ${outfiles[*]} &>/dev/null &
		pid_pipe_out="$!"
		echo $pid_pipe_out > "$path_tmp"/pid_pipe
		pipe_done=1
	    fi
	elif [ ! -z "$print_out" ]; then
	    cp "$path_tmp"/pipe_files.txt "$print_out"
	fi
    fi
}
