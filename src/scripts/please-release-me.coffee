# Description:
#   Please Release Me! This is a specific module as we no longer sing please release me.
#   We need to bring that back. I'm sure Metcalfe will love this
#
# Commands:
#   please release me - Returns a link to a youtube video to allow us to listen to the great man
#
# Author:
#   pstack

humperdink = [
  "http://www.youtube.com/watch?v=6S9ecXWCBCc",
  "http://www.youtube.com/watch?v=kOcW9gZv68A",
  "http://www.youtube.com/watch?v=AZLqZ_H_nZc",
  "http://www.youtube.com/watch?v=ch_Fz2Np-Z4"
]

module.exports = (robot) ->

  robot.respond /please release me/i, (msg) ->
    msg.reply msg.random humperdink
