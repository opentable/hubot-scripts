// Description:
//   TODO
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot status show aliases - List all aliases
//
// Author:
//   christriddle

var Url = require('url'),
    aliases,
    logger;

module.exports = function(robot){
  logger = robot.logger;

  robot.brain.on('loaded', function(){
      aliases = robot.brain.data.deploymentAliases || {};
  });

  robot.respond(/deploy (\S+)$/i, function(msg){
    deploy(msg);
  });

  robot.respond(/deployment show last successful build for (\S+)$/i, function(msg){
    showLastSuccessfulBuild(msg);
  });

  robot.respond(/deployment show last successful deployment$/i, function(msg){
    showLastSuccessfulDeploy(msg);
  });

  robot.respond(/deployment show aliases$/i, function(msg){
    showAliases(msg);
  });

  robot.respond(/deployment set alias (\S+) (\S+) (\S+)$/i, function(msg){
    setAlias(msg, robot);
  });

  robot.respond(/deployment clear alias (\S+)$/i, function(msg){
    clearAlias(msg, robot);
  });

  robot.respond(/deploy all the things/i, function(msg){
    msg.send("I don't see why I should")
  });

};

var deploy = function(msg){


},

showLastSuccessfulBuild = function(msg){
  var app = msg.match[1];
  var alias = aliases[app]; // todo: check if this exists

  if (!alias){
    logger.error("No such application");
    return;
  }

  getBuildsFromBuildType(msg, alias.mainBuildTypeId, function(builds){

        var lastBuild = builds.build[0];
        msg.send("Last build: " + lastBuild.number + " Success:" + lastBuild.status);

        //var lastSuccessfulBuild = builds.build[0];
        //if both same, show build number
        //if different, show both
    });
},

getBuildsFromBuildType = function(msg, buildTypeId, callback){
  var buildsUrl = "http://teamcity/httpAuth/app/rest/buildTypes/id:" + buildTypeId + "/builds";
  logger.info("Getting from: " + buildsUrl);

  msg.http(buildsUrl)
    .headers({Accept: 'application/json', Authorization: 'Basic Y3JpZGRsZTpXaXphcmRNb25rZXkx'})
    .get()(function(err, res, body){
        if (err){
          logger.error("Error occured when retrieving builds. " + err);
        }
        else if (res.statusCode >= 300)
        {
          logger.error(res.statusCode + " status code when retrieving builds. Body: " + body);
        }
        else{
          logger.debug(body);
          callback(JSON.parse(body));
        }
    });
},

getBuildInfo = function(buildId){
  var url = "http://teamcity/httpAuth/app/rest/builds/" + buildId;
},

pinBuild = function(buildTypeId){

  var builds = getBuildsFromBuildType(buildTypeId);

  var lastBuild = response.build[0];
  if (lastBuild.status !== "SUCCESS"){
    throw new Error("The last build must be successful");
  }

  var lastBuildDetailed = getBuildInfo(lastBuild.id);
  if (lastBuildDetailed.pinned){
    throw new Error("The last successful build has already been pinned");
  }

  // PUT
  var pinUrl = "http://teamcity/httpAuth/app/rest/builds/" + lastBuildDetailed.id + "/pin";
},

runDeployment = function(){
  var builds = getBuildsFromBuildType(buildTypeId); // Use prod team city

  var deployUrl = "http://http://teamcity-prod.otenv.com//httpAuth/app/rest/buildQueue";
  // POSTP
  //<build>
  //  <buildType id="buildConfID"/>
  //</build>
},

showAliases = function(msg){
  var response = '';
  for(var al in aliases){
    response += al + ':\n';
    for(var s in aliases[al]){
      response += "  " + s + ": " + aliases[al][s] + "\n";
    }
  }
  msg.send(response || "No aliases set");
},


setAlias = function(msg, robot){
    var bits = {
        app: msg.match[1],
        mainBuildTypeId: msg.match[2],
        deployBuildTypeId: msg.match[3]
    };

    // todo: validate build type ids

    if(!aliases[bits.app]){
        aliases[bits.app] = {};
    }

    aliases[bits.app] = { mainBuildTypeId: bits.mainBuildTypeId, deployBuildTypeId: bits.deployBuildTypeId };
    robot.brain.data.deploymentAliases = aliases;

    msg.send('Ok, alias for ' + bits.app + ' was set');
},

clearAlias = function(msg, robot){
    var app = msg.match[1];

    delete aliases[app];
    robot.brain.data.deploymentAliases = aliases;

    msg.send('Ok, alias for ' + app + ' was cleared');
};
