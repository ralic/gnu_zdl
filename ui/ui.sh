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

function show_downloads_extended {
    header_z
    header_box "Modalità interattiva"
    echo -e "\n${BBlue}Directory di destinazione:${Color_Off} $PWD\n"
    if [ ! -z "$daemon_pid" ]; then
	print_c 1 "$PROG è attivo in modalità demone\n"
    fi
    data_stdout
    if [ $? == 1 ]; then
	last_out=$(( ${#pid_out[*]}-1 ))
	for j in `seq 0 $last_out`; do
	    human_length ${length_out[$j]} # --> $length_H
	    
	    header_dl "Numero download: $j"
	    check_pid ${pid_out[$j]}
	    if [ $? == 1 ] && [ ! -f "${file_out[$j]}" ] && [ ! -z "${progress_out[$j]}" ]; then
		print_c 3 "${downloader_out[$j]} sta scaricando a vuoto: ${file_out[$j]} non esiste"
	    fi
	    
	    echo -e "${BBlue}File:${Color_Off} ${file_out[$j]}" 
	    [ ! -z "${alias_file_out[$j]}" ] && echo "${BBlue}Alias:${Color_Off} ${alias_file_out[$j]}"
	    echo -e "${BBlue}Grandezza:${Color_Off} ${length_H} ${BBlue}Downloader:${Color_Off} ${downloader_out[$j]}\n${BBlue}Link:${Color_Off} ${url_out[$j]}"
	    
	    progress="${progress_out[$j]}"
	    color=${Green}
	    
	    check_pid ${pid_out[$j]}
	    if [ $? != 1 ]; then
		progress="Download non attivo"
		color=${BRed}
	    fi

	    length_saved=0
	    [ -f "${file_out[$j]}" ] && length_saved=`ls -l "./${file_out[$j]}" | awk '{ print($5) }'`
	    if [ -f "${file_out[$j]}" ] && [ ! -f "${file_out[$j]}.st" ] && [ "$length_saved" == "${length_out[$j]}" ];then
		progress="Download completato"
		color=${BGreen}
	    fi
	    echo -e "${BBlue}Stato:${color} ${progress}${Color_Off}"
	    echo
	done
	return 1
    else
	print_c 3 "Nessun download rilevato in $PWD\n"	
    fi
}


function human_length { ## input in bytes
    if [ ! -z $1 ]; then
	length_B=$1
	length_K=$(( $length_B/1024 ))
	length_M=$(( $length_K/1024 ))
	if (( $length_M>0 )); then
	    length_H="${length_M} M"
	elif (( $length_K>0 )); then
	    length_H="${length_K} K"
	else
	    length_H="${length_B} B"
	fi
    fi
}


function interactive {
    while true ; do
	daemon_pid=$(ps ax |grep "$prog" |grep "$PWD" |grep "silent" |awk '{print $1}')
	header_z
	header_box "Modalità interattiva"
	echo
		#show_data_alive
	unset list file_stdout file_out alias_file_out url_out downloader_out pid_out length_out
	show_downloads_extended
	if [ $? == 1 ] || [ ! -z "$daemon_pid" ]; then
	    header_box "Opzioni"
	    echo -e "\t<${BRed} r ${Color_Off}> riavvia o elimina un download dalla gestione di $name_prog"
	    echo -e "\t<${BGreen} c ${Color_Off}> cancella i file temporanei dei download completati\n"
	    echo -e "\t<${BBlue} q ${Color_Off}> esci da $PROG --interactive"
	    [ ! -z "$daemon_pid" ] && echo -e "\t<${BBlue} s ${Color_Off}> ferma il demone di $PROG avviato in questa directory ($PWD) lasciando attivi Axel e Wget se avviati\n"
	    echo -e "\t<${BBlue} * ${Color_Off}> aggiorna lo stato\n"
	    cursor off
	    read -n 1 -t 15 action
	    cursor on
	    if [ "$action" == "r" ]; then
		fclear
		header_z
		echo
		show_downloads_extended
		header_box "Seleziona (Riavvia o Elimina)"
		print_c 2 "Seleziona i numeri dei download da eliminare o (solo se attivi) da riavviare, separati da spazi (puoi non scegliere):"
		read input
		if [ ! -z "$input" ]; then
		    unset inputs
		    inputs=( $input )
		    #last_out=$(( ${#pid_out[*]}-1 ))
		    options=`seq 0 $last_out`
		    echo
		    header_box "Riavvia o Elimina"
		    print_c 2 "Vuoi che i download selezionati siano terminati definitivamente oppure che siano riavviati automaticamente più tardi?"
		    echo
		    echo -e "\t<${BYellow} r ${Color_Off}> per riavviarli

\t<${BRed} e ${Color_Off}> per eliminarli definitivamente (e cancellare il file scaricato)
\t<${BRed} t ${Color_Off}> per terminarli definitivamente SENZA cancellare il file scaricato (cancella il link dalla coda di download)

\t<${BGreen} c ${Color_Off}> per cancellare i file temporanei dei download completati

\t<${BBlue} * ${Color_Off}> per tornare alla schermata principale\n"
		    print_c 2 "Scegli cosa fare: ( r | e | t | c | * ):"
		    read input2
		    
		    if [ "$input2" == "r" ]; then
			for i in ${inputs[*]}; do
			    kill ${pid_out[$i]} 2>/dev/null # && ( print_c 1 "Download terminato: ${file_in[$i]} (${url_in[$i]})" ; read )
			    if [ ! -f "${file_out[$i]}.st" ] && [ ! -f "${alias_file_out[$i]}.st" ]; then
				rm -f "${file_out[$i]}" "${alias_file_out[$i]}"
			    fi
			done
		    elif [ "$input2" == "e" ]; then
			for i in ${inputs[*]}; do
			    kill ${pid_out[$i]} 2>/dev/null
			    rm -f "${file_out[$i]}" "${alias_file_out[$i]}" "${file_out[$i]}.st" "${alias_file_out[$i]}.st" "$path_tmp"/"${file_out[$i]}_stdout.tmp"
			    links_loop - "${url_out[$i]}"
			done
		    elif [ "$input2" == "t" ]; then
			for i in ${inputs[*]}; do
			    kill ${pid_out[$i]} 2>/dev/null
			    rm -f "$path_tmp"/"${file_out[$i]}_stdout.tmp"
			    links_loop - "${url_out[$i]}"
			done
		    elif [ "$input2" == "c" ]; then
			clean_completed
		    fi
		fi
	    elif [ "$action" == "c" ]; then
		clean_completed
	    elif [ "$action" == "q" ]; then
		fclear
		break
	    elif [ "$action" == "s" ]; then
		kill $daemon_pid 2>/dev/null
		fclear
		break
	    fi
	else
	    break
	fi
    done
    echo -e "\e[0m\e[J"
    exit
}


function show_downloads {
    if [ "$daemon" != "true" ]; then
	echo
	header_dl "Downloading in $PWD"

	unset progress
	data_stdout
	if [ $? == 1 ]; then
	    last_stdout=$(( ${#pid_out[*]}-1 ))
	    for i in `seq 0 $last_stdout`; do
		if [ ! -z "${url_out[$i]}" ]; then
		    length_saved=0
		    [ -f "${file_out[$i]}" ] && length_saved=`ls -l "./${file_out[$i]}" 2>/dev/null| awk '{ print($5) }'`

		    echo -e " ${BBlue}File:${Color_Off} ${file_out[$i]}"
		    echo -e " ${BBlue}Link:${Color_Off} ${url_out[$i]}"
		    progress="${progress_out[$i]}"
		    color=1
		    
		    check_pid "${pid_out[$i]}"
		    if [ $? != 1 ]; then
			progress="Download non attivo"
			color=3
		    fi
		    if [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "$length_saved" == "${length_out[$i]}" ];then
			progress="Download completato"
			color=1
		    fi
		    print_c $color " ${downloader_out[$i]}: ${progress}"
		    ii=$(( $i+1 ))
		    if [ $i != $last_stdout ] && [ -f "$path_tmp/${file_out[$ii]}_stdout.tmp" ]; then # && [ "$multi" == "1" ]; then
			separator "─"
		    fi
		fi
	    done
	else
	    echo
	    print_c 3 " Nessun download rilevato"
	    echo
	fi
	separator "─"
	echo -e "\n\n\n"
	unset progress
    fi

    sleeping $sleeping_pause
}


function sleeping {
    timer=$1
    if [ -z "$daemon" ] && [ -z "$pipe" ]; then
	read -t $timer -n 1 action
	case $action in
	    q) exit ;;
	    i) zdl -i
		header_z
		print_c 1 "\nModalità interattiva terminata: di seguito l'output di gestione dei download\n"
		header_box "Modalità non interattiva/standard"
		;;
	esac
    else
	/bin/sleep $timer
    fi
}