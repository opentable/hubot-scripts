# Description:
#   Post
#   This script used in conjunction with tcWebHooks: http://tcplugins.sourceforge.net/info/tcWebHooks makes Hubot to send you build status messages.
#
#   Install web hooks, set this sucker up with Hubot, make sure you have a port configured for him, and set the HUBOT_ROOM_TO_RECEIVE_TEAM_CITY_BUILD_RESULTS
#   environment variable and Bob's your uncle you'll get build status messages from Hubot in your chat rooms.
#
# Dependencies:
#   None
#
# Configuration:
#
# Commands:
#   None
#
# Notes:
#   All the properties available on the build object can be found at the properties list at the top of this file:
#   http://sourceforge.net/apps/trac/tcplugins/browser/tcWebHooks/trunk/src/main/java/webhook/teamcity/payload/format/WebHookPayloadJsonContent.java
#
# Author:
#   cubanx 

Robot = require('hubot').Robot

module.exports = (robot)->
  robot.router.post "/hubot/build", (req, res)->
    user = robot.brain.userForId 'broadcast'
    user.room = req.query.room 
    user.type = 'groupchat'
    build = req.body.build

    robot.send user, "#{build.message} ran on agent: #{build.agentName}, #{build.buildStatusUrl}"

    res.end "that tickles:" + process.env.PORT
