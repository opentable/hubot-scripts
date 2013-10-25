# Description:
#   Show current reviews api status page
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot status review productfeed  - Returns the current state of the Reviews API ProductFeed
#   hubot status <application> [<monitor>] - Returns the current state of the given application

aliases = {
	review: 'http://192.168.220.181/review/service-status/'
}

module.exports = (robot) ->
  robot.respond /status (.*) (.*)$/i, (msg) ->
    status msg

# NOTE: messages contains new lines for some reason.
formatString = (string) ->
  decodeURIComponent(string.replace(/(\n)/gm," "))

status = (msg) ->
  msg.http('http://192.168.220.181/review/service-status/ProductFeedMonitor')
    .get() (err, res, body) ->
      json = JSON.parse(body)
      msg.send "Current Status: #{json.Status || json.status}"