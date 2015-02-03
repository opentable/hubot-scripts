# Description:
#   beavers assemble - The one and only
#
# Commands:
#   hubot beavers assemble - Beavers assemble image
#
# Author:
#   Ryan Tomlinson

beavers = [
  "http://cdn.meme.am/instances/500x/58267772.jpg"
]

module.exports = (robot) ->

  robot.respond /beavers assemble/i, (msg) ->
    msg.send msg.random beavers
