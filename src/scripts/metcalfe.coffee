# Description:
#   metcalfe me - The one and only
#
# Commands:
#   hubot metcalfe me - An array of Partridge images
#   hubot andym me - As above
#
# Author:
#   Ryan Tomlinson

metcalfes = [
  "http://slayermusings.files.wordpress.com/2012/11/sports-casual.jpg",
  "http://cdn.images.express.co.uk/img/dynamic/79/285x214/343509_1.jpg",
  "http://static.guim.co.uk/sys-images/Guardian/Pix/audio/video/2013/7/25/1374755714850/Alan-Partridge-in-Norwich-005.jpg",
  "http://www.thedrum.com/uploads/drum_basic_article/115831/main_images/AP_0.jpg"
]

module.exports = (robot) ->

  robot.respond /(metcalfe|andym) me/i, (msg) ->
    msg.send msg.random metcalfes