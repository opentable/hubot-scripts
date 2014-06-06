// Description:
//   Do deployments via hubot
//
// Dependencies:
//   Underscore
//   Q
//   Util
//
// Configuration:
//   HUBOT_TEAMCITY_DEV_USERNAME
//   HUBOT_TEAMCITY_DEV_PASSWORD
//   HUBOT_TEAMCITY_DEV_HOSTNAME
//   HUBOT_TEAMCITY_PROD_USERNAME
//   HUBOT_TEAMCITY_PROD_PASSWORD
//   HUBOT_TEAMCITY_PROD_HOSTNAME
//
// Commands:
//   hubot deploy <app alias> - Deploys app by pinning last successful build then triggering the deploy 'build'
//   hubot status show aliases - List all aliases
//   hubot status set alias <app alias> <dev build type id> <deploy build type id> - Sets an alias
//   hubot status clear aliases <app alias> - Clears an alias
//   hubot deployment show last successful build for <app alias> - Shows the last successful build
//   hubot deployment show last successful deployment for <app alias> - Shows the last successful deployment
//
// Author:
//   christriddle

var _ = require('underscore'),
    q = require('q'),
    util = require('util'),
    aliases,
    logger,
    devTeamCity = {
        restUrl:  util.format("http://%s/httpAuth/app/rest/", process.env.HUBOT_TEAMCITY_DEV_HOSTNAME),
        host: process.env.HUBOT_TEAMCITY_DEV_HOSTNAME,
        user: process.env.HUBOT_TEAMCITY_DEV_USERNAME,
        password: process.env.HUBOT_TEAMCITY_DEV_PASSWORD
    },
    prodTeamCity = {
        restUrl: util.format("http://%s/httpAuth/app/rest/", process.env.HUBOT_TEAMCITY_PROD_HOSTNAME),
        host: process.env.HUBOT_TEAMCITY_PROD_HOSTNAME,
        user: process.env.HUBOT_TEAMCITY_PROD_USERNAME,
        password: process.env.HUBOT_TEAMCITY_PROD_PASSWORD
    };

module.exports = function (robot) {
    logger = robot.logger;

    robot.brain.on('loaded', function () {
        aliases = robot.brain.data.deploymentAliases || {};
    });

    robot.respond(/deploy (\S+)$/i, function (msg) {
        doDeploy(msg);
    });

    robot.respond(/deployment show last successful build for (\S+)$/i, function (msg) {
        showLastSuccessfulBuild(msg);
    });

    robot.respond(/deployment show last successful deployment for (\S+)$/i, function (msg) {
        showLastSuccessfulDeploy(msg);
    });

    robot.respond(/deployment show aliases$/i, function (msg) {
        showAliases(msg);
    });

    robot.respond(/deployment set alias (\S+) (\S+) (\S+)$/i, function (msg) {
        setAlias(msg, robot);
    });

    robot.respond(/deployment clear alias (\S+)$/i, function (msg) {
        clearAlias(msg, robot);
    });

    robot.respond(/deploy all the things/i, function (msg) {
        msg.send("I don't see why I should")
    });

};

var doDeploy = function (msg) {

        var alias = msg.match[1];
        var app = aliases[alias];
        msg.alias = alias;

        if (!app) {
            msg.send("No app with alias: " + alias);
            return;
        }

        getBuilds(msg, app.mainBuildTypeId, devTeamCity)
            .then(validateLastBuildIsSuccessful)
            .then(function(lastSuccessfulBuildId){
                return getBuildInfo(msg, lastSuccessfulBuildId, devTeamCity);
            })
            .then(function(lastSuccessfulBuild) {
                return pinAndTrigger(msg, lastSuccessfulBuild, app.deployBuildTypeId, prodTeamCity);
            })
            .catch(function(err){
                msg.send("There was an error. " + err);
            })
            .done();
    },

    showLastSuccessfulBuild = function (msg) {
        var alias = msg.match[1];
        var app = aliases[alias];

        if (!app) {
            msg.send("No app with alias: " + alias);
            return;
        }

        getBuilds(msg, app.mainBuildTypeId, devTeamCity)
            .then(function (builds) {
                var lastBuild = builds[0];
                msg.send(util.format("Last build: %s [%s]", lastBuild.number, lastBuild.status));

                if (lastBuild.status !== "SUCCESS") {
                    var lastSuccessful = _.find(builds, function (x) { return x.status === "SUCCESS"; });

                    if (lastSuccessful) {
                        msg.send("Last successful build: " + lastSuccessful.number);
                    }
                    else {
                        msg.send("There has been no successful builds for this project");
                    }
                }
            })
            .catch(function(err){
                msg.send("An error occurred:" + err);
            });
    },

    showLastSuccessfulDeploy = function(msg){
        var alias = msg.match[1];
        var app = aliases[alias];

        if (!app) {
            msg.send("No app with alias: " + alias);
            return;
        }

        getBuilds(msg, app.deployBuildTypeId, prodTeamCity)
            .then(function(builds){
                var lastSuccessful = _.find(builds, function (x) { return x.status === "SUCCESS"; });

                if (lastSuccessful) {
                    msg.send("Last successful deployment: " + lastSuccessful.number);
                }
                else {
                    msg.send("There has been no successful deployments for this project");
                }
            })
            .catch(function(err){
                msg.send("An error occured:" + err);
            });
    },

    getBuilds = function (msg, buildTypeId, teamCityConfig) {
        var deferred = q.defer();

        var buildsUrl = util.format("%sbuildTypes/id:%s/builds", teamCityConfig.restUrl, buildTypeId);
        logger.info("Getting builds from: " + buildsUrl);

        msg.http(buildsUrl)
            .headers({Accept: 'application/json', Authorization: getAuthHeader(teamCityConfig)})
            .get()(function (err, res, body) {
                if (err) {
                    deferred.reject(err);
                }
                else if (res.statusCode >= 300) {
                    deferred.reject(new Error(res.statusCode + " status code when retrieving builds. Body: " + body));
                }
                else {
                    deferred.resolve(JSON.parse(body).build);
                }
            });

        return deferred.promise;
    },

    getBuildInfo = function (msg, buildId, teamCityConfig, callback, errorCallback) {
        var deferred = q.defer();

        var buildUrl = util.format("%sbuilds/%s", teamCityConfig.restUrl, buildId);
        logger.info("Getting build info from: " + buildUrl);

        msg.http(buildUrl)
            .headers({Accept: 'application/json', Authorization: getAuthHeader(teamCityConfig)})
            .get()(function (err, res, body) {
                if (err) {
                    deferred.reject(deferred);
                }
                else if (res.statusCode >= 300) {
                    deferred.reject(new Error(res.statusCode + " status code when retrieving builds. Body: " + body));
                }
                else {
                    deferred.resolve(JSON.parse(body));
                }
            });

        return deferred.promise;
    },

    validateLastBuildIsSuccessful = function(builds){
        return q.fcall(function() {

            var lastBuild = builds[0];
            if (lastBuild.status !== "SUCCESS") {
                throw new Error("The last build must be successful");
            }
            logger.info("Build ID: " + lastBuild.id);
            return lastBuild.id;
        });
    },

    pinAndTrigger = function(msg, lastSuccessfulBuild, deployBuildTypeId, prodTeamCity){
        if (lastSuccessfulBuild.pinned) {
            msg.send("This app is already pinned");
            return triggerBuild(msg, deployBuildTypeId, prodTeamCity);
        }
        else {
            return pinBuild(msg, lastSuccessfulBuild.id, prodTeamCity)
                .then(function(){
                    return triggerBuild(msg, deployBuildTypeId, prodTeamCity)
                });
        }
    },

    pinBuild = function(msg, buildId, teamCityConfig){
        var deferred = q.defer();

        var pinUrl = devTeamCity.restUrl + "builds/" + buildId + "/pin";
        logger.info("Pinning build by PUT: " + pinUrl);

        msg.http(pinUrl)
            .headers({Accept: 'application/json', Authorization: getAuthHeader(teamCityConfig)})
            .put()(function (err, res, body) {
                if (err) {
                    deferred.reject(err);
                }
                else if (res.statusCode >= 300) {
                    deferred.reject(new Error(res.statusCode + " status code when pinning build. Body: " + body));
                }
                else {
                    deferred.resolve();
                }
            });

        return deferred.promise;
    },

    triggerBuild = function (msg, buildTypeId, teamCityConfig) {
        var deferred = q.defer();

        // There is a better way to do this if we had TC 8.1 onwards (see git commit history for REST version)
        var triggerBuildUrl = util.format("http://%s:%s@%s/httpAuth/action.html?add2Queue=%s",
            teamCityConfig.user, teamCityConfig.password, teamCityConfig.host, buildTypeId);
        logger.info("Triggering build with GET: " + triggerBuildUrl);

        msg.http(triggerBuildUrl)
            .headers({
                Accept: 'application/json',
                Authorization: getAuthHeader(teamCityConfig)
            })
            .get()(function (err, res, body) {
                if (err) {
                    deferred.reject(err);
                }
                else if (res.statusCode >= 300) {
                    deferred.reject(new Error(res.statusCode + " status code when triggering build. Body: " + body));
                }
                else {
                    msg.send("Successfully triggered deployment for " + msg.alias);
                    deferred.resolve();
                }
        });

        return deferred.promise;
    },

    getAuthHeader = function(teamCityConfig){
        return "Basic " + new Buffer(teamCityConfig.user + ":" + teamCityConfig.password).toString("base64");
    },

    showAliases = function (msg) {
        var response = '';
        for (var al in aliases) {
            response += al + ':\n';
            for (var s in aliases[al]) {
                response += "  " + s + ": " + aliases[al][s] + "\n";
            }
        }
        msg.send(response || "No aliases set");
    },

    setAlias = function (msg, robot) {
        var bits = {
            alias: msg.match[1],
            mainBuildTypeId: msg.match[2],
            deployBuildTypeId: msg.match[3]
        };

        // todo: validate build type ids

        if (!aliases[bits.alias]) {
            aliases[bits.alias] = {};
        }

        aliases[bits.alias] = { mainBuildTypeId: bits.mainBuildTypeId, deployBuildTypeId: bits.deployBuildTypeId };
        robot.brain.data.deploymentAliases = aliases;

        msg.send('Ok, alias for ' + bits.alias + ' was set');
    },

    clearAlias = function (msg, robot) {
        var alias = msg.match[1];

        delete aliases[alias];
        robot.brain.data.deploymentAliases = aliases;

        msg.send('Ok, alias for ' + alias + ' was cleared');
    };
