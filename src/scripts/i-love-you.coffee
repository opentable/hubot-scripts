# Description:
#   Simple declaration of love for hubot. Everyone needs their ego massaged
#
#
# Configuration:
#   None
#
# Commands:
#   hubot i love you
#
# Author:
#   pstack

module.exports = (robot) ->

  robot.respond /(.*) love(s?) you/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    msg.reply "Right back at ya! http://thumbs.dreamstime.com/x/gold-robot-character-holding-heart-both-hands-create-d-humanoid-robot-series-30164419.jpg"
