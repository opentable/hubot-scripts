// Description:
//   TeamCity build information and kick off builds
//
// Dependencies:
//   None
//
// Configuration:
//   HUBOT_TEAMCITY_USERNAME = <user name>
//   HUBOT_TEAMCITY_PASSWORD = <password>
//   HUBOT_TEAMCITY_HOSTNAME = <host : port>
//   HUBOT_TEAMCITY_SCHEME = <http || https> defaults to http if not set.
//
// Commands:
//   hubot tc show aliases - Returns a list of ALL aliases stored in the brain
//   hubot tc set alias <alias> <buildType> - Sets an association between alias and build type
//   hubot tc clear alias <alias> - Deletes this alias from the brain
//   hubot show me builds - Lists ALL running builds. I'm not sure how useful this is. May wish to delete
//   hubot <tc build start|deploy> <alias> OR <buildType> - Kicks off a build in TeamCity
//
//   DEPRECATED - THOUGH ONLY TEMPORARILY
//   hubot status <application> <monitor> [<server>] - Returns the current state of the given application
//   hubot status show aliases - List all aliases
//   hubot status set alias <app> <server> <url> - Stores a new alias for the specified application
//   hubot status clear alias <app> [<server] - Clears an alias
//   hubot lbstatus <application> [<server>] - Returns lbstatus of the given application
//
// Original Authors:
//   Micah Martin and Jens Jahnke
// Contributor:
//   Ryan Tomlinson


(function() {
  var util, _;

  util = require('util');
  _ = require('underscore');

  module.exports = function(robot) {
    var aliases, base_url, buildTypes, createAndPublishBuildMap, getAuthHeader, getBuildType, getBuildTypes, getBuilds, getCurrentBuilds, getProjects, hostname, mapAndKillBuilds, mapBuildToNameList, mapNameToIdForBuildType, password, scheme, username;
    username = process.env.HUBOT_TEAMCITY_USERNAME;
    password = process.env.HUBOT_TEAMCITY_PASSWORD;
    hostname = process.env.HUBOT_TEAMCITY_HOSTNAME;
    scheme = process.env.HUBOT_TEAMCITY_SCHEME || "http";
    base_url = "" + scheme + "://" + hostname;
    buildTypes = [];
    aliases = {
      poapi: "bt2693"
    };
    robot.brain.on('loaded', function() {
      return aliases = robot.brain.data.teamCityBuildTypeAliases || aliases;
    });

    robot.respond(/tc show aliases/i, function(msg) {
      showAliases(msg, robot);
    });

    robot.respond(/tc set alias (\S+) (\S+)$/i, function(msg) {
      setAlias(msg, robot);
    });

    robot.respond(/tc clear alias (\S+)/i, function(msg){
      clearAlias(msg, robot);
    });

    robot.respond(/show me builds/i, function(msg) {
      showBuilds(msg, robot);
    });

    robot.respond(/(tc build start|deploy) (\S+) ?(prod)?/i, function(msg) {
      startBuild(msg, robot);
    });

    robot.respond(/tc list (projects|buildTypes|builds) ?(.*)?/i, function(msg) {
      var amount, buildTypeMatches, buildTypeRE, configuration, matches, option, project, projectRE, type;
      type = msg.match[1];
      option = msg.match[2];
      switch (type) {
        case "projects":
          return getProjects(msg, function(err, msg, projects) {
            var message, project, _i, _len;
            message = "";
            for (_i = 0, _len = projects.length; _i < _len; _i++) {
              project = projects[_i];
              message += project.name + "\n";
            }
            return msg.send(message);
          });
        case "buildTypes":
          project = null;
          if (option != null) {
            projectRE = /^\s*of (.*)/i;
            matches = option.match(projectRE);
            if ((matches != null) && matches.length > 1) {
              project = matches[1];
            }
          }
          return getBuildTypes(msg, project, function(err, msg, buildTypes) {
            var buildType, message, _i, _len;
            message = "";
            for (_i = 0, _len = buildTypes.length; _i < _len; _i++) {
              buildType = buildTypes[_i];
              message += "" + buildType.name + " of " + buildType.projectName + "\n";
            }
            return msg.send(message);
          });
        case "builds":
          configuration = option;
          project = null;
          buildTypeRE = /^\s*of (.*?) of (.+) (\d+)/i;
          buildTypeMatches = option.match(buildTypeRE);
          if (buildTypeMatches != null) {
            configuration = buildTypeMatches[1];
            project = buildTypeMatches[2];
            amount = parseInt(buildTypeMatches[3]);
          } else {
            buildTypeRE = /^\s*of (.+) (\d+)/i;
            buildTypeMatches = option.match(buildTypeRE);
            if (buildTypeMatches != null) {
              configuration = buildTypeMatches[1];
              amount = parseInt(buildTypeMatches[2]);
              project = null;
            } else {
              amount = 1;
              buildTypeRE = /^\s*of (.*?) of (.*)/i;
              buildTypeMatches = option.match(buildTypeRE);
              if (buildTypeMatches != null) {
                configuration = buildTypeMatches[1];
                project = buildTypeMatches[2];
              } else {
                buildTypeRE = /^\s*of (.*)/i;
                buildTypeMatches = option.match(buildTypeRE);
                if (buildTypeMatches != null) {
                  configuration = buildTypeMatches[1];
                  project = null;
                }
              }
            }
          }

          return getBuilds(msg, project, configuration, amount, function(err, msg, builds) {
            if (!builds) {
              msg.send("Could not find builds for " + option);
              return;
            }
            return createAndPublishBuildMap(builds, msg);
          });
      }
    });

    showBuilds = function(msg, robot){
      return getCurrentBuilds(msg, function(err, builds, msg) {
        if (typeof builds === 'string') {
          builds = JSON.parse(builds);
        }
        if (builds['count'] === 0) {
          msg.send("No builds are currently running");
          return;
        }
        return createAndPublishBuildMap(builds['build'], msg);
      });
    }

    startBuild = function(msg, robot){
      var buildName, buildTypeMatches, buildTypeRE, configuration, project, isProd;
      configuration = buildName = msg.match[2];
      isProd = msg.match[3];
      project = null;
      buildTypeRE = /(.*?) of (.*)/i;
      buildTypeMatches = buildName.match(buildTypeRE);

      if (buildTypeMatches != null) {
        configuration = buildTypeMatches[2];
        project = buildTypeMatches[3];
      }

      if (isProd)
      {
          console.log("WARNING: This is a production build");
          switchToProductionTeamCityInstance();
      }

      return mapNameToIdForBuildType(msg, project, configuration, function(msg, buildType) {
        var url;
        if (!buildType) {
          msg.send("Build type " + buildName + " was not found");
          switchToDevelopmentTeamCityInstance();
          return;
        }
        url = "" + base_url + "/httpAuth/action.html?add2Queue=" + buildType;
        return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
          switchToDevelopmentTeamCityInstance();
          if (res.statusCode !== 200) {
            err = body;
          }
          if (err) {
            return msg.send("Fail! Something went wrong. Couldn't start the build for some reason");
          } else {
            return msg.send("Dropped a build in the queue for " + buildName + ". Run `tc list builds of " + buildName + "` to check the status");
          }
        });
      });
    }

    showAliases = function(msg, robot) {
      var key, responseContainingAliases, value;
      responseContainingAliases = '';
      for (key in aliases) {
        value = aliases[key];
        responseContainingAliases += key + ": " + value + "\n";
      }
      return msg.send(responseContainingAliases);
    }

    setAlias = function(msg, robot){
        var options =  {
            alias: msg.match[1],
            buildType: msg.match[2]
        }

        aliases[options.alias] = options.buildType;
        robot.brain.data.teamCityBuildTypeAliases = aliases;
        msg.send('SUCCESS! Added ' + options.alias + ' to ' + options.buildType)
    }

    clearAlias = function(msg, robot){
      var alias = msg.match[1];

      delete aliases[alias];

      msg.send('Successfully removed the alias' + alias) 
    }

    switchToProductionTeamCityInstance = function() {
        //console.log("WARNING: Switching to production instance.");
        hostname = process.env.HUBOT_TEAMCITY_PROD_HOSTNAME;
        username = process.env.HUBOT_TEAMCITY_PROD_USERNAME;
        password = process.env.HUBOT_TEAMCITY_PROD_PASSWORD;
    }

    switchToDevelopmentTeamCityInstance = function() {
        //console.log("INFO: Switching to development instance.");
        username = process.env.HUBOT_TEAMCITY_USERNAME;
        password = process.env.HUBOT_TEAMCITY_PASSWORD;
        hostname = process.env.HUBOT_TEAMCITY_HOSTNAME;
    }

    getAuthHeader = function() {
      return {
        Authorization: "Basic " + (new Buffer("" + username + ":" + password).toString("base64")),
        Accept: "application/json"
      };
    };

    getBuildType = function(msg, type, callback) {
      var url;
      url = "" + base_url + "/httpAuth/app/rest/buildTypes/" + type;
      return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
        if (res.statusCode !== 200) {
          err = body;
        }
        return callback(err, body, msg);
      });
    };

    getCurrentBuilds = function(msg, type, callback) {
      var url;

      if (arguments.length === 2) {
        if (Object.prototype.toString.call(type) === "[object Function]") {
          callback = type;
          url = "http://" + hostname + "/httpAuth/app/rest/builds/?locator=running:true";
        }
      } else {
        url = "http://" + hostname + "/httpAuth/app/rest/builds/?locator=buildType:" + type + ",running:true";
      }

      return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
        if (res.statusCode !== 200) {
          err = body;
        }
        return callback(err, body, msg);
      });
    };

    getProjects = function(msg, callback) {
      var url;
      url = "" + base_url + "/httpAuth/app/rest/projects";
      return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
        var projects;
        if (res.statusCode !== 200) {
          err = body;
        }
        if (!err) {
          projects = JSON.parse(body).project;
        }
        return callback(err, msg, projects);
      });
    };

    getBuildTypes = function(msg, project, callback) {
      var projectSegment, url;
      projectSegment = '';
      if (project != null) {
        projectSegment = '/projects/name:' + encodeURIComponent(project);
      }
      url = "" + base_url + "/httpAuth/app/rest" + projectSegment + "/buildTypes";
      return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
        if (res.statusCode !== 200) {
          err = body;
        }
        if (!err) {
          buildTypes = JSON.parse(body).buildType;
        }
        return callback(err, msg, buildTypes);
      });
    };

    getBuilds = function(msg, project, configuration, amount, callback) {
      var projectSegment, url;
      projectSegment = '';
      if (project != null) {
        projectSegment = "/projects/name:" + (encodeURIComponent(project));
      }
      url = "" + base_url + "/httpAuth/app/rest" + projectSegment + "/buildTypes/id:" + (aliases[configuration]) + "/builds";
      return msg.http(url).headers(getAuthHeader()).query({
        locator: ["count:" + amount, "running:any"].join(",")
      }).get()(function(err, res, body) {
        var builds;
        if (res.statusCode !== 200) {
          err = body;
        }
        if (!err) {
          builds = JSON.parse(body).build.splice(0, amount);
        }
        return callback(err, msg, builds);
      });
    };

    mapNameToIdForBuildType = function(msg, project, name, callback) {
      var execute, result;
      if (aliases[name]) {
        callback(msg, aliases[name]);
        return;
      }
      execute = function(buildTypes) {
        var buildType;
        buildType = _.find(buildTypes, function(bt) {
          return bt.name === name && ((project == null) || bt.projectName === project);
        });
        if (buildType) {
          return buildType.id;
        }
      };
      result = execute(buildTypes);
      if (result) {
        callback(msg, result);
        return;
      }
      return getBuildTypes(msg, project, function(err, msg, buildTypes) {
        return callback(msg, execute(buildTypes));
      });
    };

    mapBuildToNameList = function(build) {
      var id, msg, url;
      id = build['buildTypeId'];
      msg = build['messengerBot'];
      url = "http://" + hostname + "/httpAuth/app/rest/buildTypes/id:" + id;

      return msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
        var baseMessage, buildName, message, status;
        if (!(res.statusCode = 200)) {
          err = body;
        }
        if (!err) {
          buildName = JSON.parse(body).name;
          baseMessage = "#" + build.number + " of " + buildName + " " + build.webUrl;
          if (build.running) {
            status = build.status === "SUCCESS" ? "**Winning**" : "__FAILING__";
            message = "" + status + " " + build.percentageComplete + "% Complete :: " + baseMessage;
          } else {
            status = build.status === "SUCCESS" ? "OK!" : "__FAILED__";
            message = "" + status + " :: " + baseMessage;
          }
          return msg.send(message);
        }
      });
    };

    createAndPublishBuildMap = function(builds, msg) {
      var build, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = builds.length; _i < _len; _i++) {
        build = builds[_i];
        build['messengerBot'] = msg;
        _results.push(mapBuildToNameList(build));
      }
      return _results;
    };

    mapAndKillBuilds = function(msg, name, id, project) {
      var comment;
      comment = "killed by hubot";
      return getCurrentBuilds(msg, function(err, builds, msg) {
        if (typeof builds === 'string') {
          builds = JSON.parse(builds);
        }
        if (builds['count'] === 0) {
          msg.send("No builds are currently running");
          return;
        }
        return mapNameToIdForBuildType(msg, project, name, function(msg, buildType) {
          var build, buildName, url, _i, _len, _ref, _results;
          buildName = buildType;
          _ref = builds['build'];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            build = _ref[_i];
            if (name === 'all' || (build['id'] === parseInt(id) && (id != null)) || (build['buildTypeId'] === buildName && (buildName != null) && (id == null))) {
              url = "" + base_url + "/ajax.html?comment=" + comment + "&submit=Stop&buildId=" + build['id'] + "&kill";
              _results.push(msg.http(url).headers(getAuthHeader()).get()(function(err, res, body) {
                if (res.statusCode !== 200) {
                  err = body;
                }
                if (err) {
                  return msg.send("Fail! Something went wrong. Couldn't stop the build for some reason");
                } else {
                  return msg.send("The requested builds have been killed");
                }
              }));
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
      });
    };
  };

}).call(this);
