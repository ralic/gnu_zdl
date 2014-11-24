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

if [ "$url_in" != "${url_in//'junkyvideo.com'}" ]; then
    input_hidden "$(wget --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -q -O- $url_in)" 
    file_in="${post[fname]}"

    echo -n -e "${BBlue}1/3) "
    countdown+ 6
    #### Per scaricare il file a bassa risoluzione (streaming video), seguire questa pista:
    ## wget -q --post-data="$post_data" "$url_in" -O- |grep file:

    data_html=$(wget -q "http://junkyvideo.com/dl?op=get_vid_versions&file_code=${post[id]}" -O- |grep download_video)
    unset data
    data=( $(sed -r "s|^.+\('(.+)','(.+)','(.+)'\).+$|\1 \2 \3|g" <<< "$data_html") )

    echo -n -e "${BBlue}2/3) "
    countdown+ 6
    wget -q "http://junkyvideo.com/dl?op=download_orig&id=${data[0]}&mode=${data[1]}&hash=${data[2]}" -O "$path_tmp/zdl.tmp"
    url_in_file=$(cat "$path_tmp/zdl.tmp" |grep "$file_in" |sed -r 's|^[^"]+\"([^"]+).+|\1|g' )
    unset post_data

    echo -n -e "${BBlue}3/3) "
    countdown+ 6
    axel_parts=4
fi

