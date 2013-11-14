# Description:
#   Please Release Me! This is a specific module as we no longer sing please release me.
#   We need to bring that back. I'm sure Metcalfe will love this
#
# Commands:
#   please release me - Returns a link to a youtube video to allow us to watch the song
#
# Author:
#   pstack

humperdink = [
  ""
]

module.exports = (robot) ->

  robot.respond /please release me/i, (msg) ->
    msg.reply msg.random humperdink
