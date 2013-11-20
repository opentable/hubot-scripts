# Description:
#   Spud Me - Definitely not a racist script to display hilarious potato images
#
# Commands:
#   hubot spud me - Sends an image of an Irish favourite
#   hubot stacko me - As above
#
# Author:
#   Ryan Tomlinson

spuds = [
  "http://webspace.webring.com/people/mc/christina2320/stpats/irishpotato.gif",
  "http://grocery-genie.com/wp-content/uploads/2013/03/mr-potato-head.jpg",
  "http://shakebakeandparty.files.wordpress.com/2013/03/drunken-irish-potato-1.jpg",
  "http://www.mtnking.com/images/promotions/irish/irish_tommytater.gif"
]

module.exports = (robot) ->

  robot.respond /(spud|stacko) me/i, (msg) ->
    msg.send msg.random spuds