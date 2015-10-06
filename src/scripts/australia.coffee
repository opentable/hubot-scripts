# Description:
#   australia assemble - Standup for International New Markets Team
#
# Commands:
#   hubot australia assemble - Australia assemble image
#
# Author:
#   Ryan Tomlinson

australia = [
  "http://i190.photobucket.com/albums/z295/Neighbourschick/neighbours.jpg"
]

module.exports = (robot) ->

  robot.respond /australia assemble/i, (msg) ->
    msg.send msg.random australia
