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


function update_zdl-wise {
    if [ ! -e "/cygdrive" ]; then
	print_c 1 "Compilazione automatica di zdl-wise.c"
	gcc extensions/zdl-wise.c -o extensions/zdl-wise 2>/dev/null 
    fi
}


function update_zdl-conkeror {
    if [ -f "$HOME/.conkerorrc" ]; then
	[ -f "$path_conf/conkerorrc.zdl" ] && rm "$path_conf/conkerorrc.zdl"
	text_conkerorrc=$(cat "$HOME/.conkerorrc")
	if [ "$text_conkerorrc" != "${text_conkerorrc//$path_conf\/conkerorrc.zdl}" ]; then
	    cp "$HOME/.conkerorrc" "$HOME/.conkerorrc.old"
	    echo "${text_conkerorrc//require(\"$path_conf\/conkerorrc.zdl\");}" > "$HOME/.conkerorrc"
	fi
	test=$(cat "$HOME/.conkerorrc"|grep "$SHARE/extensions/conkerorrc.zdl" |tail -n 1)
	test2=$(echo "${test#*'//'}" |grep "$SHARE/extensions/conkerorrc.zdl")
	if [ -z "$test" ]; then
	    echo -e "\n// ZigzagDownLoader\nrequire(\"$SHARE/extensions/conkerorrc.zdl\");" >> "$HOME/.conkerorrc"
	elif [ "$test" != "$test2" ] && [ ! -z "$test2" ]; then
	    print_c 3 "\nLa funzione ZDL di Conkeror è stata disattivata dall'utente nel file "$HOME"/.conkerorrc: per riattivarla, cancella i simboli di commento \"\\\\\""
	fi
    fi
}

function try {
    cmd=$*
    $cmd 2>/dev/null
    if [ "$?" != 0 ]; then
	sudo $cmd 
	if [ "$?" != 0 ]; then
	    su -c "$cmd" || ( print_c 3 "$failure"; return 1 )
	fi
    fi
}

function update {
    PROG=ZigzagDownLoader
    prog=zdl
    BIN="/usr/local/bin"
    SHARE="/usr/local/share"
    URL_ROOT="http://download.savannah.gnu.org/releases/zdl/"
    axel_url="http://www.inventati.org/zoninoz/html/upload/files/axel-2.4-1.tar.bz2" #http://fd0.x0.to/cygwin/release/axel/axel-2.4-1bl1.tar.bz2
    success="Aggiornamento completato"
    failure="Aggiornamento non riuscito"
    path_conf="$HOME/.$prog"
    
    header_box "\e[1mAggiornamento automatico di ZigzagDownLoader\e[0m\n"

    rm -r "$path_tmp"/*
    cd "$path_tmp"
    print_c 1 "Download in corso: attendere..."
    wget "$URL_ROOT" -r -l 1 -A gz,sig,txt -np -nd -q
    cd ..
    if [ -f "$path_conf"/zdl.sig ]; then
	test_version=$(diff "$path_conf"/zdl.sig "$path_tmp"/*.sig )
    fi
    if [ -z "$test_version" ] && [ -f "$path_conf"/zdl.sig ]; then
	print_c 1 "$PROG è già alla versione più recente"
    else
	cd "$path_tmp"
	package=$(ls *.tar.gz)
	print_c 1 "Aggiornamento di $PROG con $package"
	tar -xzf "$package"

	mv "${package%.tar.gz}" $prog
	cd $prog
	update_zdl-wise

	chmod +rx -R .
	print_c 1 "Aggiornamento automatico in $BIN"
	try mv zdl zdl-xterm $BIN
	[ "$?" != 0 ] && return

	[ -e /cygdrive ] && ( mv ${prog}.bat / ) && print_c 1 "\nScript batch di avvio installato: $(cygpath -m /)\zdl.bat "
	cd ..

	print_c 1 "Aggiornamento automatico in $SHARE/$prog"
	[ ! -e "$SHARE" ] && try mkdir -p "$SHARE"
	try rm -rf "$SHARE/$prog"
	try cp -r "$prog" "$SHARE"

	update_zdl-conkeror
	
	cp *.sig "$path_conf"/zdl.sig
	
	print_c 1 "Aggiornamento automatico completato"
	pause
	cd ..
	$prog ${args[*]}
	exit
    fi
}