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
//   hubot status review productfeed  - Returns the current state of the Reviews API ProductFeed
//   hubot status <application> [<monitor>] - Returns the current state of the given application

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
  robot.respond(/status (.*) (.*) (.*)$/i, function(msg){
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
    sendRequest(buildUrl(bits), msg);
  });
},

validateRequest = function(bits, msg, callback){
  if(!aliases[bits.app]){
    msg.send("the alias '"+bits.app+"' does not exist you fuckhead");
    return;
  }
  if(!aliases[bits.app][bits.server]){
    msg.send("the server '"+bits.server+"' does not exist for app '"+bits.app+"' you tosspot");
    return;
  }

  callback();
},

buildUrl = function(bits){
  return aliases[bits.app][bits.server] + bits.monitor;
},

sendRequest = function(url, msg){
  logger.info(url);
  msg.http(url)
    .get()(function(err, res, body){
      var json = JSON.parse(body);
      var status = json.Status || json.status;
      if(!status){
        msg.send("I didn't get a valid response, you're SOL, sorry");
        return;
      }
      if(status === "Unknown"){
        msg.send("That monitor does not exist you wanker");
        return;
      }
      msg.send("Current Status: " + (json.Status || json.status));
    });
},

showAliases = function(msg){
  var response = '';
  for(al in aliases){
    response += al + ':\n';
    for(s in aliases[al]){
      response += "  " + s + ": " + aliases[al][s] + "\n";
    }
  }
  msg.send(response);
};