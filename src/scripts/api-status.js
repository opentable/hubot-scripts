// Description:
//   Show current reviews api status page
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot status <application> <monitor> [<server>] - Returns the current state of the given application
//   hubot status show aliases - List all aliases
//   hubot status set alias <app> <server> <url> - Stores a new alias for the specified application
//   hubot status clear alias <app> [<server] - Clears an alias
//   hubot lbstatus <application> [<server>] - Returns lbstatus of the given application
//
// Author:
//   andyroyle

var Url = require('url'),
    aliases,
    logger;

module.exports = function(robot){
  logger = robot.logger;

  robot.brain.on('loaded', function(){
      aliases = robot.brain.data.apiStatusAliases || {};
  });

  robot.respond(/status ((?![show|set|clear])|\S+) (\S+)(?:\s)?(\S+)?$/i, function(msg){
    status(msg);
  });

  robot.respond(/status show aliases$/i, function(msg){
    showAliases(msg);
  });

  robot.respond(/status set alias (\S+) (\S+) (\S+)$/i, function(msg){
    setAlias(msg, robot);
  });

  robot.respond(/status clear alias (\S+)(?:\s)?(\S+)?$/i, function(msg){
    clearAlias(msg, robot);
  });

  robot.respond(/lbstatus ((?![show|set|clear])|\S+)(?:\s)?(\S+)?$/i, function(msg){
    lbstatus(msg);
  });
};

var status = function(msg){
  var bits = {
    app: msg.match[1],
    monitor: msg.match[2],
    server: msg.match[3]
  };

  validateRequest(bits, msg, function(){
    for(var i=0; i<bits.server.length; i++){
        sendRequest(buildUrl(bits.app, '/service-status/' + bits.monitor, bits.server[i]), msg, bits.server[i], function(status, servername){
            if(!status){
                return invalidResponse(msg);
            }
            if(status === "Unknown"){
               return unknownMonitor(msg);
            }
            msg.send(bits.app + " " + bits.monitor + " " + servername + ", Current Status: " + status);
        });
    }
  });
},

lbstatus = function(msg){
    var bits = {
        app: msg.match[1],
        server: msg.match[2]
    };

    validateRequest(bits, msg, function(){
        for(var i=0; i<bits.server.length; i++){
            sendRequest(buildUrl(bits.app, '/_lbstatus', bits.server[i]), msg, bits.server[i], function(status, servername){
                if(!status){
                    return invalidResponse(msg);
                }
                msg.send(bits.app + " " + servername + ", Current Status: " + status);
            });
        }
    });
},

validateRequest = function(bits, msg, callback){
  if(!aliases[bits.app]){
    return unknownAlias(msg, bits.app);
  }
  if(!bits.server){
    bits.server = getServersForAlias(bits.app);
  }
  else if(!aliases[bits.app][bits.server]){
    return unknownServer(msg, bits.app, bits.server);
  }
  else{
      bits.server = [bits.server];
  }
  callback();
},

buildUrl = function(app, monitor, server){
  return aliases[app][server] + monitor;
},

sendRequest = function(url, msg, servername, cb){
  logger.info(url);
  msg.http(url)
    .get()(function(err, res, body){
      var json;
      try{
          json = JSON.parse(body);
      }
      catch(exception){
          logger.warning("response was not json, returning as raw");
          cb(body, servername);
          return;
      }
      cb(json.Status || json.status, servername);
    });
},

showAliases = function(msg){
  var response = '';
  for(var al in aliases){
    response += al + ':\n';
    for(var s in aliases[al]){
      response += "  " + s + ": " + aliases[al][s] + "\n";
    }
  }
  msg.send(response || "No aliases set, or at least, none worth showing to you");
},

getServersForAlias = function(app){
  var res = [];
  for(var s in aliases[app]){
    res.push(s);
  }
  return res;
},

setAlias = function(msg, robot){
    var bits = {
        app: msg.match[1],
        server: msg.match[2],
        url: msg.match[3]
    };

    var url = Url.parse(bits.url);

    if(!url.protocol || !url.host){
        msg.send("Check yo damn urls dawg");
        return;
    }

    if(!aliases[bits.app]){
        aliases[bits.app] = {};
    }

    aliases[bits.app][bits.server] = bits.url;
    robot.brain.data.apiStatusAliases = aliases;
    msg.send('Ok, alias for ' + bits.app + ' ' + bits.server + ' was set');
},

clearAlias = function(msg, robot){
    var app = msg.match[1],
        server = msg.match[2];

    if(!server){
        delete aliases[app];
        msg.send('Ok, all aliases for ' + app + ' were cleared');
    }
    else{
        delete aliases[app][server];
        msg.send('Ok, alias for ' + app + ' ' + server + ' was cleared');
    }

    robot.brain.data.apiStatusAliases = aliases;
},

unknownMonitor = function(msg){
    msg.send("That monitor does not exist you wanker");
},

invalidResponse = function(msg){
    msg.send("I didn't get a valid response, you're SOL, sorry");
},

unknownAlias = function(msg, app){
    msg.send("the alias '" + app + "' does not exist you fuckhead");
},

unknownServer = function(msg, app, server){
    msg.send("the server '" + server + "' does not exist for app '" + app + "' you tosspot");
};