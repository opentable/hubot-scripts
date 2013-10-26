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

var aliases = {
  review: {
    'prod-web1': 'http://192.168.220.181/review/service-status/',
    'prod-web2': 'http://192.168.220.182/review/service-status/',
    'preprod-web1': 'http://10.21.6.26/review/service-status/',
    'preprod-web2': 'http://10.21.4.101/review/service-status/'
  },
  promotedoffer: {
    'prod-web1': 'http://192.168.220.181/promoted-offer/service-status/',
    'prod-web2': 'http://192.168.220.182/promoted-offer/service-status/',
    'preprod-web1': 'http://10.21.6.26/promoted-offer/service-status/',
    'preprod-web2': 'http://10.21.4.101/promoted-offer/service-status/'
  }
},

logger;

module.exports = function(robot){
  logger = robot.logger;
  robot.respond(/status (\S+) (\S+)(?:\s)?([\S|\S]+)?$/i, function(msg){
    status(msg);
  });

  robot.respond(/status show aliases$/i, function(msg){
    showAliases(msg);
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
        sendRequest(buildUrl(bits.app, bits.monitor, bits.server[i]), msg, bits.server[i], function(status, servername){
            if(!status){
                msg.send("I didn't get a valid response, you're SOL, sorry");
                return;
            }
            if(status === "Unknown"){
                msg.send("That monitor does not exist you wanker");
                return;
            }
            msg.send(bits.app + " " + bits.monitor + " " + servername + ", Current Status: " + status);
        });
    }
  });
},

validateRequest = function(bits, msg, callback){
  if(!aliases[bits.app]){
    msg.send("the alias '" + bits.app + "' does not exist you fuckhead");
    return;
  }
  if(!bits.server){
    bits.server = getServersForAlias(bits.app);
  }
  else if(!aliases[bits.app][bits.server]){
    msg.send("the server '" + bits.server + "' does not exist for app '" + bits.app + "' you tosspot");
    return;
  }
  else{
      bits.server = [bits.server];
  }
  logger.debug(bits);
  callback();
},

buildUrl = function(app, monitor, server){
  return aliases[app][server] + monitor;
},

sendRequest = function(url, msg, servername, cb){
  logger.info(url);
  msg.http(url)
    .get()(function(err, res, body){
      var json = JSON.parse(body);
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
  msg.send(response);
},

getServersForAlias = function(app){
  var res = [];
  for(var s in aliases[app]){
    res.push(s);
  }
  return res;
};