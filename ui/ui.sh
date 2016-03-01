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
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz    
# zoninoz@inventati.org
#

function show_downloads {
    if [ ! -f "$path_tmp/.stop_stdout" ] && [ -z "$zdl_mode" ]
    then
	if data_stdout
	then
	    awk -f $path_usr/libs/common.awk      \
		-f $path_usr/ui/colors.awk.sh     \
		-f $path_usr/ui/ui.awk            \
		-v col="$COLUMNS"                 \
		-v Color_Off="$Color_Off"         \
		-v Background="$Background"       \
		-e "BEGIN {$awk_data display()}" 
	fi
    else
	data_stdout
    fi
}

function show_downloads_lite {
    (( odd_run++ ))
    (( odd_run>1 )) && odd_run=0
    
    if data_stdout "no_check"
    then
	awk -f $path_usr/libs/common.awk      \
	    -f $path_usr/ui/colors.awk.sh     \
	    -f $path_usr/ui/ui.awk            \
	    -v col="$COLUMNS"                 \
	    -v zdl_mode="lite"                \
	    -v odd_run="$odd_run"             \
	    -v Color_Off="$Color_Off"         \
	    -v Background="$Background"       \
	    -e "BEGIN {$awk_data display()}" 

    elif [ -f "$start_file" ]
    then
	fclear
	header_dl "ZigzagDownLoader in $PWD"
	print_c 1 "\n Connessione in corso..."
    fi
}

function show_downloads_extended {
    header_z
    header_box_interactive "Modalità interattiva"
    [ -f "$path_tmp/downloader" ] && downloader_in=$(cat "$path_tmp/downloader")
    echo -e "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"

    if ! check_instance_daemon
    then
	print_c 1 "$PROG è attivo in modalità demone\n"
    else
	if ! check_instance_prog
	then
	    echo -e "${BGreen}$PROG è attivo in $PWD in modalità standard nel terminale $tty\n${Color_Off}"
	else
	    echo -e "${BRed}Non ci sono istanze attive di $PROG in $PWD\n${Color_Off}"
	fi
    fi
    if data_stdout "no_check"
    then
	awk -f $path_usr/libs/common.awk          \
	    -f $path_usr/ui/colors.awk.sh         \
	    -f $path_usr/ui/ui.awk                \
	    -v col="$COLUMNS"                     \
	    -v zdl_mode="extended"                \
	    -v Color_Off="$Color_Off"             \
	    -v Background="$Background"           \
	    -e "BEGIN {$awk_data display()}" 
    fi
}


function services_box {
    header_z
    header_box_interactive "Estensioni"
    print_C 4 "\nVideo in streaming saltando il player del browser:"
    cat $path_usr/streaming.txt 2>/dev/null
    
    print_C 4 "\nFile hosting:"
    cat $path_usr/hosting.txt 2>/dev/null

    print_C 4 "\nLink generati dal web (anche dopo captcha):"
    echo -e "$(cat $path_usr/generated.txt 2>/dev/null) ed altri servizi"
    
    print_C 4 "\nShort links:"
    cat $path_usr/shortlinks.txt 2>/dev/null

    print_C 4 "\nTutti i file scaricabili con le seguenti estensioni dei browser:"
    echo -e "Flashgot di Firefox/Iceweasel/Icecat, funzione 'M-x zdl' di Conkeror e script 'zdl-xterm' (XXXTerm/Xombrero e altri)"

    print_C 4 "\nTutti i file scaricabili con i seguenti programmi:"
    cat $path_usr/programs.txt 2>/dev/null
    echo
}

function commands_box {
    header_dl "Comandi in modalità standard output (M è il tasto Meta, cioè <Alt>)"
    echo -e "<${BGreen} M-x RETURN ${Color_Off}>\tesegue i download (qui sotto, elencare i link uno per riga) [e${BGreen}x${Color_Off}ec]
<${BGreen} M-e ${Color_Off}>\t\tavvia l'${BGreen}e${Color_Off}ditor predefinito
<${BGreen} M-c ${Color_Off}>\t\t${BGreen}c${Color_Off}ancella le informazioni dei download completati
<${BYellow} M-i ${Color_Off}>\t\tmodalità ${BYellow}i${Color_Off}nterattiva

<${BRed} M-q ${Color_Off}>\t\tchiudi ZDL senza interrompere i downloader [${BRed}q${Color_Off}uit]
<${BRed} M-k ${Color_Off}>\t\tuccidi tutti i processi [${BRed}k${Color_Off}ill]

<${BBlue} M-t ${Color_Off}>\t\tsfoglia il ${BBlue}t${Color_Off}utorial
<${BBlue} M-l ${Color_Off}>\t\t${BBlue}l${Color_Off}ista dei servizi abilitati"

}

function standard_box {
    [ -n "$lite" ] && header_lite=" LITE"
    header_box "Modalità in standard output${header_lite}"
    echo -e -n "$init_msg"
    
    [ -f "$path_tmp/downloader" ] && 
	downloader_in=$(cat "$path_tmp/downloader")
    print_c 0 "\n${BBlue}Downloader:${Color_Off} $downloader_in\t${BBlue}Directory:${Color_Off} $PWD\n"
    #[ -z "$1" ] && services_box
    
    commands_box
    if [ -z "$1" ] &&
	   [ -n "$binding" ]
    then
	echo
	header_box "Readline: immetti URL e link dei servizi"
    
    elif [ -z "$lite" ] &&
	   [ -z "$binding" ]
    then
	separator-
	echo
    fi
}

function trap_sigint {
    if (( "$#">0 ))
    then
	kill_pids="kill -9 $@ $pid_prog"
	trap "$kill_pids" SIGINT
    else
	trap "trap SIGINT; stty echo; kill -9 $loops_pid; exit 1" SIGINT
    fi
}


function bindings {
    trap_sigint
    check_instance_prog
    bind -x "\"\ei\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\ee\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\el\":\"change_mode list\"" 2>/dev/null
    bind -x "\"\et\":\"change_mode info\"" 2>/dev/null
    bind -x "\"\eq\":\"clean_countdown; stty echo; kill -1 $loops_pid $pid_prog\"" &>/dev/null
    bind -x "\"\ek\":\"clean_countdown; stty echo; kill_downloads; kill -9 $loops_pid $pid_prog $pid\"" &>/dev/null
    bind -x "\"\ec\":\"no_complete=true; data_stdout; unset no_complete; export READLINE_LINE=c\"" &>/dev/null
}

function change_mode {
    local cmd=$1

    touch "$path_tmp/.stop_stdout"
    stty echo

    case $cmd in
	interactive)
	    zdl -i
	    ;;
	
	editor)
	    $editor "$path_tmp"/links_loop.txt
	    ;;
    
	info)
	    command -v pinfo &>/dev/null &&
		pinfo -x zdl ||
		    info zdl
	    ;;
	
	list)
	    zdl --list-extensions
	    ;;
    esac

    stty -echo
    rm -f "$path_tmp/.stop_stdout"
    export READLINE_LINE=" "
    
    [ -z "$lite" ] ||
	[ -n "$binding" ] &&
	    header_z &&
	    standard_box

    [ "$binding" == 1 ] &&
	print_c 2 "${msg_end_input}" #'Immissione URL terminata: premi invio per avviare i download'
	
    [ -z "$lite" ] &&
	[ -z "$binding" ] &&
	print_c 1 "\nAttendi..."
}

function interactive {
    trap "trap SIGINT; exit" SIGINT

    while true
    do
	header_z
	header_box_interactive "Modalità interattiva"

	unset tty list file_stdout file_out url_out downloader_out pid_out length_out 
	show_downloads_extended
	num_dl=$(cat "$path_tmp/dl-mode")
	
	[ ! -f "$path_tmp/dl-mode" ] && num_dl=1
	if [ -z "$num_dl" ]
	then
	    num_downloads=illimitati
	else
	    num_downloads=$num_dl
	fi
	
	header_box_interactive "Opzioni [numero download alla volta: $num_downloads]"
	echo -e "<${BYellow} s ${Color_Off}> ${BYellow}s${Color_Off}eleziona uno o più download (per riavviare, eliminare, riprodurre file audio/video)\n
<${BGreen} e ${Color_Off}> modifica la coda dei link da scaricare, usando l'${BGreen}e${Color_Off}ditor predefinito\n"
	
	[[ -f "$path_tmp/downloader" && $(cat "$path_tmp/downloader") == Axel ]] && 
	    echo -e "<${BGreen} w ${Color_Off}> scarica con ${BGreen}w${Color_Off}get"
	
	[[ -f "$path_tmp/downloader" && $(cat "$path_tmp/downloader") == Wget ]] && 
	    echo -e "<${BGreen} a ${Color_Off}> scarica con ${BGreen}a${Color_Off}xel"

	echo -e "<${BGreen} 1-9 ${Color_Off}> scarica ${BGreen}un numero da 1 a 9${Color_Off} file alla volta
<${BGreen} m ${Color_Off}> scarica ${BGreen}m${Color_Off}olti file alla volta\n"

	[ -z "$tty" ] &&
	    [ -z "$daemon_pid" ] &&
	    echo -e "<${BGreen} d ${Color_Off}> avvia ${BGreen}d${Color_Off}emone"

	echo -e "<${BGreen} c ${Color_Off}> ${BGreen}c${Color_Off}ancella i file temporanei dei download completati\n
<${BRed} K ${Color_Off}> interrompi tutti i download e ogni istanza di ZDL nella directory (${BRed}K${Color_Off}ill-all)"

	[ -n "$daemon_pid" ] && 
	    echo -e "<${BRed} Q ${Color_Off}> ferma il demone di $name_prog in $PWD lasciando attivi Axel e Wget se avviati"
	
	echo -e "\n<${BBlue} q ${Color_Off}> esci da $PROG --interactive (${BBlue}q${Color_Off}uit)"
	echo -e "<${BBlue} * ${Color_Off}> ${BBlue}aggiorna lo stato${Color_Off} (automatico ogni 15 secondi)\n"
	cursor off
	read -e -n 1 -t 15 action
	cursor on

	case "$action" in
	    s)
		fclear
		header_z
		echo
		show_downloads_extended
		header_box_interactive "Seleziona (Riavvia/sospendi, Elimina, Riproduci audio/video)"
		echo -e -n "${BYellow}Seleziona i numeri dei download, separati da spazi (puoi non scegliere):${Color_Off}\n"

		read -e input

		if [ -n "$input" ]
		then
		    unset inputs
		    inputs=( $input )
		    echo
		    header_box_interactive "Riavvia o Elimina"
		    echo -e -n "${BYellow}Cosa vuoi fare con i download selezionati?${Color_Off}\n\n"

		    echo -e "<${BYellow} r ${Color_Off}> ${BYellow}r${Color_Off}iavviarli se è attiva un'istanza di ZDL, altrimenti sospenderli
<${BRed} E ${Color_Off}> ${BRed}e${Color_Off}liminarli definitivamente (e cancellare il file scaricato)
<${BRed} T ${Color_Off}> ${BRed}t${Color_Off}erminarli definitivamente SENZA cancellare il file scaricato (cancella il link dalla coda di download)

<${BGreen} p ${Color_Off}> riprodurre (${BGreen}p${Color_Off}lay) i file audio/video

<${BBlue} * ${Color_Off}> ${BBlue}schermata principale${Color_Off}\n"
		    echo -e -n "${BYellow}Scegli cosa fare: ( r | E | T | p | * ):${Color_Off}\n"

		    read -e input2

		    for ((i=0; i<${#inputs[*]}; i++))
		    do
			[[ ! "${inputs[$i]}" =~ ^[0-9]+$ ]] && unset inputs[$i]
		    done

		    case "$input2" in
			r)
			    for i in ${inputs[*]}
			    do
				kill -9 ${pid_out[$i]} &>/dev/null
				if [ ! -f "${file_out[$i]}.st" ]
				then
				    rm -f "${file_out[$i]}" 
				fi
			    done
			    ;;

			E)
			    for i in ${inputs[*]}
			    do
				kill -9 ${pid_out[$i]} &>/dev/null
				rm -f "${file_out[$i]}" "${file_out[$i]}.st" "$path_tmp"/"${file_out[$i]}_stdout.tmp"
				links_loop - "${url_out[$i]}"
			    done
			    ;;

			T)
			    for i in ${inputs[*]}
			    do
				kill -9 ${pid_out[$i]} &>/dev/null
				rm -f "$path_tmp"/"${file_out[$i]}_stdout.tmp"
				links_loop - "${url_out[$i]}"
			    done
			    ;;

			p)
			    if [ -n "$player" ] #&>/dev/null
			    then
				for i in ${inputs[*]}
				do
				    playing_files+=( "${file_out[$i]}" )
				done

				nohup $player "${playing_files[@]}" &>/dev/null &
				unset playing_files

			    else
				configure_key 10
				get_conf
			    fi
			    ;;
		    esac
		fi
		;;
	    
	    [0-9])
		echo "$action" > "$path_tmp/dl-mode"
		;;
	
	    m)
		echo > "$path_tmp/dl-mode"
		;;
	    
	    e)
		$editor "$path_tmp/links_loop.txt"
		;;
	    
	    c)
		no_complete=true
		data_stdout
		unset no_complete
		;;
	    
	    q)
		fclear
		break
		;;
	    
	    a)
		echo "Axel" > "$path_tmp/downloader"
		;;
	    
	    w)
		echo "Wget" > "$path_tmp/downloader"
		;;
	    
	    Q)
		kill "$daemon_pid"
		unset daemon_pid
		;;
	    
	    K)
		kill_downloads
		[ -n "$daemon_pid" ] &&
		    kill -9 "$daemon_pid" &&
		    unset daemon_pid &>/dev/null

		! check_instance_prog &&
		    [ $pid != $PPID ] &&
		    kill -9 $pid &>/dev/null
		;;
	    
	    d)
		[ -z "$tty" ] &&
		    zdl --daemon
		;;
	esac

	unset action input2
    done
    echo -e "\e[0m\e[J"

    exit
}

function sleeping {
    timer=$1
    ## l'interazione è stata sostituita con 'bind' e i processi sono in background: lo schermo non è più influenzato dalla tastiera
    #
    # if [ -z "$zdl_mode" ] && [ -z "$pipe" ]; then
    # 	read -es -t $timer -n 1 
    # else
	sleep $timer
    # fi
}
