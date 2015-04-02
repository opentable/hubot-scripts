# Description:
#   dublin assemble - Standup for Dublin Team
#
# Commands:
#   hubot dublin assemble - Dublin assemble image
#
# Author:
#   Ryan Tomlinson

beavers = [
  "http://i.imgur.com/zlVFnTL.jpg"
]

module.exports = (robot) ->

  robot.respond /dublin assemble/i, (msg) ->
    msg.send msg.random beavers
