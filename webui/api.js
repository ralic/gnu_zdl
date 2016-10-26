//  ZigzagDownLoader (ZDL)
//  
//  This program is free software: you can redistribute it and/or modify it 
//  under the terms of the GNU General Public License as published 
//  by the Free Software Foundation; either version 3 of the License, 
//  or (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful, 
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License 
//  along with this program. If not, see http://www.gnu.org/licenses/. 
//  
//  Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
//  
//  For information or to collaborate on the project:
//  https://savannah.nongnu.org/projects/zdl
//  
//  Gianluca Zoni (author)
//  http://inventati.org/zoninoz
//  zoninoz@inventati.org
// 

var ZDL = {
    'path': '',
    'visible': [],
    'conf_items': [
	'downloader',
	'axel_parts',
	'aria2_connections',
	'max_dl',
	'background',
	'language',
	'reconnecter',
	'autoupdate',
	'player',
	'editor',
	'resume',
	'zdl_mode',
	'tcp_port',
	'udp_port',
	'socket_port',
	'browser'
    ]
};

String.prototype.toHtmlEntities = function() {
    return this.replace(/./gm, function(s) {
	return "&#" + s.charCodeAt(0) + ";";
    });
};

String.prototype.fromHtmlEntities = function(string) {
    return (string+"").replace(/&#\d+;/gm,function(s) {
	return String.fromCharCode(s.match(/\d+/gm)[0]);
    });
};

var objectToSource = function (obj) {
    return JSON.stringify(obj).replace(/\"/g, "'");
};

var cleanInput = function (str) {
    return str.replace(/(\r\n|\n|\r)/gm, "");
};

var getUriParam = function (name, url) {
    if (!url) url = document.location.href;
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( url );
    return results == null ? null : results[1];
};

var isJsonString = function (str) {
    try {
	JSON.parse(str);
    } catch (e) {
	return false;
    }
    return true;
};

var load = function (method, url, async, callback, params) {
    var data;
    var req = new XMLHttpRequest();
    req.open(method, encodeURI(url), async);     // .replace("#", "%23")
    req.onload = function () {
    	if (req.status === 200) {
	    if (typeof callback === 'function') {
		callback(req.responseText, params);
		return true;
	    }
	    
	    switch (getUriParam('cmd', url)) {
	    case 'get-data':
		ZDL.data = req.responseText;
		break;
	    }

    	} else {
    	    alert("Error " + req.status);
    	}
    };
    req.send();
};

var getData = function () {
    load ('GET', '?cmd=get-data', false);
    if (isJsonString(ZDL.data))
	return JSON.parse(ZDL.data);
    else
	return false;
};

var showInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'visible');
    ZDL.visible[path + ' ' + link] = true;
};

var hideInfoLink = function (id, path, link) {
    document.getElementById(id).setAttribute('class', 'hidden');
    ZDL.visible[path + ' ' + link] = false;
};


var cleanComplete = function () {
    var query = "?cmd=clean-complete&path=" + ZDL.path;
    return load ('GET',
		 query,
		 true);
};

var singleLink = function (spec) {
    var that = spec;
    
    that.stop = function () {
	var query = "?cmd=stop-link&path=" + that.path + "&link=" + encodeURIComponent(that.link);
	return load ('GET', query, true); 
    };
    
    that.del = function () {
	var query = "?cmd=del-link&path=" + that.path + "&link=" + encodeURIComponent(that.link);
	return load ('GET', query, true); 	
    };

    that.play = function () {
	if (document.location.hostname === 'localhost') {
	    var query = "?cmd=play-link&path=" + that.path + "&file=" + that.file;
	    return load ('GET',
			 query,
			 true,
			 function (res) {
			     if (cleanInput(res))
				 alert(res);
			 });
	} else {
	    return alert("L'anteprima è disponibile solo se connessi a localhost");
	}
    };

    return that;
};


var singlePath = function (path) {
    var that = {};
    var data = {};

    var getByAttr = function (attr) {
	for (var i = 0; i<data.length; i += 1) {
	    if (data[i].path === path) {
		return data[i][attr];
	    }
	}
    };

    that.getFreeSpace = function () {
	var query = '?cmd=get-free-space&path=' + path;
	load ('GET',
	      query,
	      true,
	      function (res){
		  if (cleanInput(res))
		      document.getElementById('path-free-space').innerHTML = res;
	      });
    };
    
    that.reconnect = function (str) {
	var query = '?cmd=reconnect&path=' + path;
	if (str)
	    query += '&loop=' + str;
	
	return load ('GET',
		     query,
		     true,
		     function(ip){
			 alert("Indirizzo IP attuale: " + ip);
		     });
    };

    that.setReconnecter = function (spec) {
	var value = document.getElementById('input-' + spec.key).value;

	if (value === 'Mai')
	    value = "false";
	else
	    value = "true";
	    
	var query =  '?cmd=reconnect&path=' + path + '&set=' + value; 
	return load ('GET',
		     query,
		     true,
		     function(res){
			 if (cleanInput(res)) {
			     alert(res);
			     document.getElementById('input-reconnect').value = "Mai"; 
			 }
		     });
    };

    that.getIP = function () {
	var query = '?cmd=get-ip';	
	return load ('GET',
		     query,
		     true,
		     function(ip){
			 alert("Indirizzo IP attuale: " + ip);
		     });
    };

    that.kill = function () {
	return load ('GET', '?cmd=kill-zdl&path=' + path, true);
    };

    that.quit = function () {
	return load ('GET', '?cmd=quit-zdl&path=' + path, true);
    };

    that.run = function () {
	return load ('GET', '?cmd=run-zdl&path=' + path, true);
    };

    that.setDownloader = function () {
	var query = '?cmd=set-downloader&path=' + path + '&dowloader=' + document.getElementById('sel-downloader').value;
	return load ('GET', query, true);
    };

    that.getDownloader = function (repeat, op) {
	var query = '?cmd=get-downloader&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (dler){
			 displayDownloader(dler);
			 
			 if (repeat)
			     singlePath(ZDL.path).getDownloader(true);
		     });
    };

    that.setMaxDownloads = function (spec) {
	var max_dl = document.getElementById('input-max-downloads').value;
	if (spec === 'no-limits')
	    max_dl = '';

	if (spec === 'no-limits' || !isNaN(parseInt(max_dl))) {
	    load ('GET',
		  '?cmd=set-max-downloads&path=' + path + '&number=' + max_dl,
		  true);
	} else {
	    alert("Immissione dati non valida: il limite massimo di downloads deve essere un numero");
	}
    };

    that.inputMaxDownloads = function (max_dl) {
	if (isNaN(max_dl))
	    max_dl = '';
	    
	var output = '<input id="input-max-downloads" type="number" value="' + max_dl + '" min="0" max="100">' +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads();\">Invia</button>" +
		"<button onclick=\"singlePath(ZDL.path).setMaxDownloads('no-limits');\">Nessun limite</button>";
	return document.getElementById('max-downloads').innerHTML = output;
    };
	
    that.getMaxDownloads = function (repeat, op) {
	var query = '?cmd=get-max-downloads&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (max_dl_str){
			 displayMaxDownloads (max_dl_str);
			 
			 if (repeat)
			     singlePath(ZDL.path).getMaxDownloads(true);
		     });
    };

    that.getLinks = function () {
	return load ('GET',
		     '?cmd=get-links&path=' + path,
		     true,
		     function (str){
			 document.getElementById('editor-links').innerHTML = "<textarea id=\"list-links\">" + str + "</textarea>" +
			     "<button onclick=\"singlePath(ZDL.path).setLinks();\">Salva</button>" +
			     "<button onclick=\"displayEditButton();\">Annulla</button>";
		     });
    };
    
    that.setLinks = function () {
	return load ('GET',
		     '?cmd=set-links&path=' + path + '&links=' + encodeURIComponent(document.getElementById('list-links').value),
		     true,
		     function (res) {
			 if (cleanInput(res)) {
			     alert("I seguenti link non sono stati accettati perché non validi o già presenti:\n" + res);
			 }
			 displayEditButton();
		     });
    };

    that.getRunStatus = function (repeat, op) {
	var query = '?cmd=get-status-run&path=' + path;

	if (op === 'force')
	    query += '&op=' + op;
	
	return load ('GET',
		     query,
		     true,
		     function (response) {
			 response = cleanInput(response);

			 if (response.match(/RELOAD/g)) {
			     singlePath(ZDL.path).getRunStatus(true, 'force');
			 }

			 if (response.match(/not-running/g)) {
			     displayStatus('not-running');
			 } else if (response.match(/running/g)) {
			     displayStatus('running');
			 }
			 
			 if (repeat)
			     singlePath(ZDL.path).getRunStatus(true);
		     });
    };

    that.addLink = function (id, link) {
	if (link) {
	    displayTorrentButton(id);
	} else {
	    link = encodeURIComponent(document.getElementById(id).value);
	    document.getElementById(id).value = '';
	}
	
	var query = "?cmd=add-link&path=" + ZDL.path + "&link=" + link;
	
	return load ('GET',
		     query,
		     true,
		     function (res) {
			 if (cleanInput(res)) {
			     alert("Il seguente link non è stato accettato perché non valido o già presente:\n" + res);
			 }
		     });
    };
    
    that.addXDCC = function (id) {
	// id: {host:,chan:,ctcp:}
	var host = encodeURIComponent(document.getElementById(id.host).value.trim());
	var chan = encodeURIComponent(document.getElementById(id.chan).value.trim());
	var ctcp = encodeURIComponent(document.getElementById(id.ctcp).value.trim());
	var errMsg = '';
		
	if (!host)
	    errMsg += "\nIRC host";
	if (!chan)
	    errMsg += "\nIRC channel";
	if (!ctcp)
	    errMsg += "\nIRC msg/ctcp";

	if (errMsg) {
	    return alert("Mancano le seguenti informazioni:\n" + errMsg);
	} else {
	    return load ('GET',
			 '?cmd=add-xdcc&path=' + path + '&host=' + host + '&chan=' + chan + '&ctcp=' + ctcp,
			 true,
			 function (res) {
			     if (cleanInput(res)) {
				 alert("Il link xdcc non è stato aggiunto perché non valido o già presente, controlla i dati inviati:\n" + res);
			     } else {
				 document.getElementById(id.host).value = '';
				 document.getElementById(id.chan).value = '';
				 document.getElementById(id.ctcp).value = '';
			     }
			 });
	}
    };

    return that;
};


var changeSection = function (section) {
    ['links', 'path', 'config', 'info', 'server'].forEach(function(item) {
	if (item === section) {
	    document.getElementById(item).style.display = 'block';
	    document.getElementById(item + '-menu').setAttribute('class', 'active');
	} else {
	    document.getElementById(item).style.display = 'none';
	    document.getElementById(item + '-menu').setAttribute('class', 'not-active');
	}
    });
};

var initClient = function (path) {
    displayTorrentButton('path-torrent');
    load ('GET', '?cmd=init-client&path=' + path, true);
}

var selectDir = function (path) {
    ZDL.path = path;
    document.getElementById('run-path').setAttribute('class', 'visible');
    document.getElementById('sel-path').innerHTML = '<div class="label-element">Agisci in:</div><div class="value">' + path + '</div>' +
 	" <button onClick=\"browseDir('" + path + "');\">Sfoglia</button><br>";
    document.getElementById('path-browse-dir').innerHTML = '';
    return initClient(path);
};

var runServer = function (port) {
    port = parseInt(port);

    if (isNaN(port) || port < 1024 || port > 65535 )
	alert('Porta non valida: deve essere un numero compreso tra 1024 e 65535');

    return load ('GET',
		 '?cmd=run-server&port=' + port,
		 true,
		 function (res) {
		     if (res.match(/already-in-use/g))
			 alert("Porta non valida: " + port + " è utilizzata da un'altra applicazione");
		     else
			 alert("Nuovo socket disponibile alla porta: " + port);
		 });
};

var getSockets = function (repeat, op) {
    var query = '?cmd=get-sockets';

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (sockets){
		     if (sockets !== '') {			 
			 displaySockets(sockets.split('\n'));
			 	
			 if (repeat)
			     getSockets(true);
		     } else {
			 document.getElementById('list-sockets-open').innerHTML = '';
			 document.getElementById('list-sockets-kill').innerHTML = '';
		     }
		 });
};

var killServer = function (port) {
    port = parseInt(port);
    if (isNaN(port))
	port = document.location.port;

    port = parseInt(port);
    return load ('GET',
		 '?cmd=kill-server&port=' + port,
		 true);
};

var killAll = function () {
    return load ('GET', '?cmd=kill-all', true);
};


window.onbeforeunload = function () {
    load ('GET', '?cmd=reset-requests&path=' + ZDL.path, true);
};

// window.onfocus = function () {
//     initClient (ZDL.path);
// };


var getConf = function (repeat, op) {
    var query = '?cmd=get-conf';

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (res) {
		     if (isJsonString(res)) {
			 displayConf(JSON.parse(res));
			 
			 if (repeat)
			     getConf(true);
		     }
		 });
};

var setConf = function (spec, value) {
    if (!value)
	value = document.getElementById('input-' + spec.key).value;
    
    if (spec.key.match(/^(axel_parts|aria2_connections|max_dl|tcp_port|udp_port|socket_port)$/)) {
	value = parseInt(value);
	if (isNaN(value) || value < spec.min || value > spec.max) {
	    return alert ('È richiesto un valore numerico compreso fra ' + spec.min + ' e ' + spec.max);
	}
    }

    load ('GET', "?cmd=set-conf&key=" + spec.key + '&value=' + value, true);	
};

var getStatus = function (repeat, op) {
    var query = '?cmd=get-status&path=' + ZDL.path;

    if (op === 'force')
	query += '&op=' + op;
    
    return load ('GET',
		 query,
		 true,
		 function (res) {
		     if (isJsonString(res)) {
			 var data = JSON.parse(res);

			 // data.status:
			 displayStatus(data.status);
			 
			 // data.downloader:
			 displayDownloader(data.downloader);
		
			 //data.maxDownloads;
			 displayMaxDownloads(data.maxDownloads);

			 //data.reconnecter;
			 displayReconnecter(data.reconnect, 'path-reconnecter');

			 //data.conf:
			 displayConf(data.conf);
			 
			 //data.sockets:
			 displaySockets(data.sockets);
		     }

		     singlePath(ZDL.path).getFreeSpace();

		     if (repeat)
			 getStatus(true);
		 });
};

var displayStatus = function (status) {
    if (status === 'not-running') {
	document.getElementById('path-status').innerHTML = '<button onclick="singlePath(ZDL.path).run();">Avvia ZDL</button>';
	
    } else if (status === 'running') {
	document.getElementById('path-status').innerHTML = '<button onclick="singlePath(ZDL.path).quit();">Termina ZDL</button>' +
	    '<button onclick="singlePath(ZDL.path).kill();">Termina ZDL e download</button>';			     
    }
};

var displayReconnecter = function (value, id) {
    if (value === 'enabled')
	value = "Ogni nuovo link";
    else
	value = "Mai";
    
    var spec = {
	"key": "reconnect",
	"value": value,
	"options": ["Ogni nuovo link","Mai"]
    };	 

    displayInputSelect(spec, id, 'singlePath(ZDL.path).setReconnecter');
};

var displayInputSelect = function (spec, id, callback) {
    // spec = {key: options: value:}
    var output = '<select id="input-' + spec.key + "\" onchange=\"" + callback + "(" + objectToSource(spec) + ");\">";

    spec.options.forEach(function(item){
	if (String(spec.value) === String(item))
	    output += "<option selected>";
	else
	    output += "<option>";
	output += item + "</option>";
    });

    document.getElementById(id).innerHTML = output;
};

var displayInputNumber = function (spec, id) {
    // spec = {key: value: min: max:}
    var output = '<input id="input-' + spec.key + '" type="number" value="' + spec.value + '" min="' + spec.min + '" max="' + spec.max + '">' +
		"<button onclick=\"setConf(" + objectToSource(spec) + ");\">Invia</button>" +
		"<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

    document.getElementById(id).innerHTML = output;
};

var displayInputText = function (spec, id) {
    // spec = {id: value: min: max:}
    var output = '<input id="input-' + spec.key + '" type="text" value="' + spec.value + '">' +
		"<button onclick=\"setConf(" + objectToSource(spec) + ");\">Invia</button>" +
		"<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

    document.getElementById(id).innerHTML = output;
};

var browseFile = function (id, path, type, key) {
    path = path.replace(/\/[^/]+\/\.\.$/,'');
    path = '/' + path.replace(/^\/+/,'');
    
    var query = '?cmd=browse&path=' + path + '&id=' + id + '&type=' + type;
    if (key)
	query += '&key=' + key;    
    
    return load ('GET',
		 query,
		 true,
		 function (res) {
		     var output = "<div class=\"value\"><b>Sfoglia:</b> " + path + "/</div>" +
			     "<button onclick=\"initClient(ZDL.path)\">Annulla</button><br>" +
			     res +
			     "<button onclick=\"initClient(ZDL.path)\">Annulla</button>";

		     document.getElementById(id).style.width = '100%';
		     document.getElementById(id).innerHTML = output;
		 });
};

var browseDir = function (path) {
    document.getElementById('run-path').setAttribute('class', 'hidden');
    path = path.replace(/\/[^/]+\/\.\.$/,'');
    path = '/' + path.replace(/^\/+/,'');

    return load ('GET',
		 '?cmd=browse-dirs&path=' + path,
		 true,
		 function (dirs) {
		     document.getElementById('sel-path').innerHTML = "<div class=\"value\"><b>Sfoglia: </b>" + path + "</div>" +
			 "<button onclick=\"selectDir('" + path + "');\">Seleziona</button>" +
			 "<button onclick=\"selectDir(ZDL.path)\">Annulla</button>";

		     document.getElementById('path-browse-dir').innerHTML = dirs;
    });
};

var displayConf = function (conf) {
    Object.keys(conf).forEach(function(item){
	var spec = {
	    "key": item,
	    "value": cleanInput(conf[item])
	};	 

	switch(item) {
	case 'downloader':
	    if (!spec.options)
		spec.options = ['Aria2','Axel','Wget'];
	case 'background':
	    if (!spec.options)
		spec.options = ['transparent','black'];
	case 'language':
	    if (!spec.options)
		spec.options = ['it_IT.UTF-8'];
	case 'resume':
	case 'autoupdate':
	    if (!spec.options) {
		spec.options = ['enabled','disabled'];
		if (spec.value !== 'enabled')
		    spec.value = 'disabled';
	    }
	case 'zdl_mode':
	    if (!spec.options)
		spec.options = ['stdout','lite','daemon'];
	    
	    displayInputSelect (spec, 'conf-' + spec.key, 'setConf');
	    break;
	    
	case 'axel_parts':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1;
		spec.max = 32;
	    }
	case 'aria2_connections':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1;
		spec.max = 16;
	    }
	case 'max_dl':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 0;
		spec.max = 100;
	    }
	case 'tcp_port':
	case 'udp_port':
	case 'socket_port':
	    if (isNaN(spec.min) || isNaN(spec.max)) {
		spec.min = 1024;
		spec.max = 65535;
	    }

 	    var output = "<button onclick=\"displayInputNumber(" + objectToSource(spec) + ",'conf-" + spec.key + "');\">Cambia</button>";
	    document.getElementById('conf-' + spec.key).innerHTML = '<div class="value">' + spec.value + '</div>' + output;
	    break;

	case 'reconnecter':
	case 'player':
	case 'editor':
	case 'browser':
	    var id_inputFile = 'input-file-' + spec.key;
	    var id_inputText = 'conf-' + spec.key + '-text';
	    
	    document.getElementById(id_inputFile).innerHTML = '<div class="value">' + spec.value + '</div>' +
		"<button onclick=\"document.getElementById('" + id_inputText + "').style.display = 'none';" +
		"browseFile('" + id_inputFile + "', ZDL.path, 'executable', '" + spec.key + "');" +
		"\">Sfoglia</button>";

	    document.getElementById(id_inputText).innerHTML = "<button onclick=\"" +
		"document.getElementById('" + id_inputFile + "').style.display = 'none';" +		
		"displayInputText (" + objectToSource(spec) + ", '" + id_inputText + "');" +
		"\">Scrivi</button>";

	    document.getElementById(id_inputFile).style.width = 'initial';
	    document.getElementById(id_inputFile).style.display = 'initial';
	    document.getElementById(id_inputText).style.display = 'initial';
	};
    });    
}

var displaySockets = function (sockets) {
    var output_kill = '';
    var output_open = '';

    sockets.forEach(function (port) {
	port = parseInt(port);
	
	if(!isNaN(port)) {
	    output_open += "<button onclick=\"window.open('" +
		document.location.protocol + '//' + 
		document.location.hostname +
		':' + port +
		"');";
	    output_kill += '<button onclick="killServer(' + port + ');';
	    if(parseInt(port) === parseInt(document.location.port))
		output_kill += "setTimeout('document.location.reload(true)', 2000);"
	    output_open += '">' + port + '</button>';
	    output_kill += '">' + port + '</button>';
	}
    });
    document.getElementById('list-sockets-open').innerHTML = output_open;
    document.getElementById('list-sockets-kill').innerHTML = output_kill;
};

var displayDownloader = function (dler) {
    dler = dler.replace(/(\r\n|\n|\r)/gm, "");
    var selector = '<select id="sel-downloader" onchange="singlePath(ZDL.path).setDownloader();">';
    
    ["Aria2", "Axel", "Wget"].forEach(function (item) {
	if (String(dler) === String(item)) {
	    selector += "<option selected>";
	    
	} else {
	    selector += "<option>"
	}
	selector += item + "</option>";
    });
    
    selector += "</select>";
    document.getElementById('downloader').innerHTML = selector;    
};

var displayMaxDownloads = function (max_dl_str) {
    var output;
    var max_dl = parseInt(max_dl_str);
    
    if (isNaN(max_dl)) {
	max_dl_str = "illimitati";
	max_dl = '';
    }
    output = "<button onclick=\"singlePath(ZDL.path).inputMaxDownloads(" + max_dl + ");\">Cambia</button>";
    document.getElementById('max-downloads').innerHTML = '<div class="value">' + max_dl_str + '</div>' + output;
};

var displayEditButton = function () {
    document.getElementById('editor-links').innerHTML = '<button onclick="singlePath(ZDL.path).getLinks();">Editor dei link</button>';
};

var displayLinks = function () {
    return load ('GET', '?cmd=get-data', true, function (str) {
	if (isJsonString(str)) {
	    var data = JSON.parse(str);
	    var output = '';
	    var visibility = 'hidden';
	    var color;
	    
	    if (typeof data === 'object') {
		for (var i=0; i<data.length; i++) {
		    if (ZDL.visible[data[i].path + ' ' + data[i].link])
			visibility = 'visible';
		    else
			visibility = 'hidden';
		    
		    output += "<div onclick=\"showInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		    output += "<div id=\"progress-bar\">" +
			"<div id=\"progress-label-file\">" + data[i].file + "</div>" +
			"<div id=\"progress-status\" style=\"width:" + data[i].percent + "%; background-color:" + data[i].color + "\"></div>" +
			"</div>";

		    output += "<div id=\"progress-label-status\">" +
			data[i].percent + '% ' +
			data[i].speed + data[i].speed_measure + ' ' +
			data[i].eta +
			"</div>" +
			"</div>";

		    output += "<div style=\"float: left; width: 100%;\" class=\"" + visibility + "\" id=\"info-" + i + "\"" + 
			" onclick=\"hideInfoLink('info-" + i + "','" + data[i].path + "','" + data[i].link + "');\">";

		    output += '<div class="background-data">' +
			'<div class="label-element">Downloader:</div>' +
			'<div class="value-data">' + data[i].downloader + "</div></div>";

		    output += '<div class="background-data">' +
			'<div class="label-element">Link:</div>' +
			'<div class="value-data">' + data[i].link + "</div></div>";

		    output += '<div class="background-data">' +
			'<div class="label-element">Path:</div>' +
			'<div class="value-data">' + data[i].path + "</div>";

		    output += "<button onclick=\"selectDir('" + data[i].path + "'); changeSection('path');\" style=\"float: left;\">Gestisci</button></div>";

		    output += '<div class="background-data">' +
			'<div class="label-element">File: </div>' +
			'<div class="value-data">' + data[i].file + "</div></div>";

		    output += '<div class="background-data">' +
			'<div class="label-element">Length: </div>' +
			'<div class="value-data">' + (data[i].length/1024/1024).toFixed(2) + "M</div></div>";

		    if (data[i].downloader.match(/^(RTMPDump|cURL)$/)) {
			output += '<div class="background-data"><div class="label-element">Streamer:</div>';
			output += '<div class="value-data">' + data[i].streamer + "</div></div>";

			output += '<div class="background-data"><div class="label-element">Playpath:</div>';
			output += '<div class="value-data">' + data[i].playpath + "</div></div>";
			
		    } else {
			output += '<div class="background-data"><div class="label-element">Url:</div>';
			output += '<div class="value-data">' + data[i].url.toHtmlEntities() + "</div></div>";
		    }

		    output += displayLinkButtons(data[i]);
		    output += '</div>';
		}
		
		document.getElementById('output-links').innerHTML = output;
	    }
	    return displayLinks();
	}
	
	document.getElementById('output-links').innerHTML = '';
	return displayLinks();
    });
};

var displayLinkButtons = function (spec) {
    var output = "<button onclick=\"singleLink({path:'" + spec.path + "', link:'" + spec.link + "'}).stop();\">Ferma il download</button>" +
	    "<button onclick=\"singleLink({path:'" + spec.path + "', link:'" + spec.link + "'}).del();\">Cancella il download</button>" +
    	    "<button onclick=\"singleLink(" + objectToSource(spec) + ").play();\">Anteprima</button>";
    return output;
};

var displayTorrentButton = function (id) {
    document.getElementById(id).innerHTML = "<button onclick=\"browseFile('" + id + "', ZDL.path, 'torrent');\">Sfoglia</button>";
};

var displayFileButton = function (spec) {
    // spec: {id:,file:}
    var output = "<button onclick=\"displayFileText(" + objectToSource(spec) + ");\">" +
	    "Leggi " + spec.file + "</button>";

    document.getElementById(spec.id).innerHTML = output;
    document.getElementById(spec.id).style.display = 'inline-block';
    document.getElementById(spec.id).style.padding = '0';
};

var displayFileText = function (spec) {
    var query = '?cmd=get-file&path=' + path + '&file=' + ZDL.path + '/' + spec.file;
    
    load ('GET',
	  query,
	  true,
	  function (res) {
	      if (cleanInput(res)) {
		  var output = '<div class="file-text">' + res + '</div>';
		  output += "<button onclick=\"displayFileText(" + objectToSource(spec) + ")\">Aggiorna</button>";
		  output += "<button onclick=\"displayFileButton(" + objectToSource(spec) + ");\">Chiudi</button>";
		  
		  document.getElementById(spec.id).innerHTML = "<b>" + spec.file + ':</b><br>' + output;
		  document.getElementById(spec.id).style.display = 'block';
		  document.getElementById(spec.id).style.padding = '1em 1em 1em 1em';
		  
	      } else {
		  alert('File ' + spec.file + ' non disponibile');
	      }
	  });
};

var init = function (path) {
    selectDir(path);
    changeSection('links');
    displayEditButton();
    displayTorrentButton('path-torrent');
    displayFileButton({id:'path-file-log',file:'zdl_log.txt'});
    displayFileButton({id:'path-file-links',file:'links.txt'});
    displayLinks();
    getStatus(true, 'force');
};

