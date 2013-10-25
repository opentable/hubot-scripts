# Description:
#   Messing with the JIRA REST API
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_URL
#   HUBOT_JIRA_USER
#   HUBOT_JIRA_PASSWORD
#   Optional environment variables:
#   HUBOT_JIRA_USE_V2 (defaults to "true", set to "false" for JIRA earlier than 5.0)
#   HUBOT_JIRA_MAXLIST
#   HUBOT_JIRA_ISSUEDELAY
#   HUBOT_JIRA_IGNOREUSERS
#
# Commands:
#   <Project Key>-<Issue ID> - Displays information about the JIRA ticket (if it exists)
#   hubot show watchers for <Issue Key> - Shows watchers for the given JIRA issue
#   hubot show comments for <Issue Key> - Shows the comments for the given JIRA issue
#   hubot show open issues for <Issue Key> - Shows the open issues for the given JQL
#   e.g. hubot show open issues for project = "The Cornered Badgers" AND fixVersion = "13.21"
#   hubot search for <JQL> - Search JIRA with JQL
#   e.g. hubot search for project = "The Cornered Badgers" AND component = "Consumer Web"
#
# Author:
#   codec

class IssueFilters
  constructor: (@robot) ->
    @cache = []

    @robot.brain.on 'loaded', =>
      jqls_from_brain = @robot.brain.data.jqls
      # only overwrite the cache from redis if data exists in redis
      if jqls_from_brain
        @cache = jqls_from_brain

  add: (filter) ->
    @cache.push filter
    @robot.brain.data.jqls = @cache

  delete: (name) ->
    result = []
    @cache.forEach (filter) ->
      if filter.name.toLowerCase() isnt name.toLowerCase()
        result.push filter

    @cache = result
    @robot.brain.data.jqls = @cache

  get: (name) ->
    result = null

    @cache.forEach (filter) ->
      if filter.name.toLowerCase() is name.toLowerCase()
        result = filter

    result
  all: ->
    return @cache

class IssueFilter
  constructor: (@name, @jql) ->
    return {name: @name, jql: @jql}


# keeps track of recently displayed issues, to prevent spamming
class RecentIssues
  constructor: (@maxage) ->
    @issues = []
  
  cleanup: ->
    for issue,time of @issues
      age = Math.round(((new Date()).getTime() - time) / 1000)
      if age > @maxage 
        #console.log 'removing old issue', issue
        delete @issues[issue]
    0

  contains: (issue) ->
    @cleanup()
    @issues[issue]?

  add: (issue,time) ->
    time = time || (new Date()).getTime() 
    @issues[issue] = time


module.exports = (robot) ->
  filters = new IssueFilters robot

  useV2 = process.env.HUBOT_JIRA_USE_V2 != "false"
  # max number of issues to list during a search
  maxlist = process.env.HUBOT_JIRA_MAXLIST || 10
  # how long (seconds) to wait between repeating the same JIRA issue link
  issuedelay = process.env.HUBOT_JIRA_ISSUEDELAY || 30
  # array of users that are ignored
  ignoredusers = (process.env.HUBOT_JIRA_IGNOREUSERS.split(',') if process.env.HUBOT_JIRA_IGNOREUSERS?) || []

  recentissues = new RecentIssues issuedelay

  get = (msg, where, cb) ->
    console.log(process.env.HUBOT_JIRA_URL + "/rest/api/latest/" + where)

    httprequest = msg.http(process.env.HUBOT_JIRA_URL + "/rest/api/latest/" + where)
    if (process.env.HUBOT_JIRA_USER)
      authdata = new Buffer(process.env.HUBOT_JIRA_USER+':'+process.env.HUBOT_JIRA_PASSWORD).toString('base64')
      httprequest = httprequest.header('Authorization', 'Basic ' + authdata)
    httprequest.get() (err, res, body) ->
        cb JSON.parse(body)

  watchers = (msg, issue, cb) ->
    get msg, "issue/#{issue}/watchers", (watchers) ->
      if watchers.errors?
        return

      cb watchers.watchers.map((watcher) -> return watcher.displayName).join(", ")

  comments = (msg, issue, cb) ->
    get msg, "issue/#{issue}/comment", (comments) ->
      if comments.errors?
        return 

      cb comments.comments.map((comment) -> return comment.body)

  info = (msg, issue, cb) ->
    get msg, "issue/#{issue}", (issues) ->
      if issues.errors?
        return

      issue =
        key: issues.key
        summary: issues.fields.summary
        project: issues.fields.project.name
        assignee: ->
          if issues.fields.assignee != null
            issues.fields.assignee.displayName
          else
            "no assignee"
        status: issues.fields.status.name
        fixVersion: ->
          if issues.fields.fixVersions? and issues.fields.fixVersions.length > 0
            issues.fields.fixVersions.map((fixVersion) -> return fixVersion.name).join(", ")
          else
            "no fix version" 
        customfield_12000: issues.fields.customfield_12000
        components: -> 
          if issues.fields.components? and issues.fields.components.length > 0
            issues.fields.components.map((component) -> return component.name).join(", ")
          else
            "no components" 
        url: process.env.HUBOT_JIRA_URL + '/browse/' + issues.key

      
      result_text = "[#{issue.key}] #{issue.summary} \nProject: #{issue.project} \nAssignee: #{issue.assignee()} \nFixVersion: #{issue.fixVersion()} \nCurrent Status: #{issue.status} \nComponents: #{issue.components()} \nBusiness Value: \n#{issue.customfield_12000}"
      
      cb result_text
      
  search = (msg, jql, cb) ->
    get msg, "search/?jql=#{escape(jql)}", (result) ->
      if result.errors?
        return
      
      resultText = "I found #{result.total} issues for your search."
      if result.issues.length <= maxlist
        cb resultText
        result.issues.forEach (issue) ->
          info msg, issue.key, (info) ->
            cb info
      else
        cb resultText + " (too many to list)"

  openIssues = (msg, jql, cb) ->
    get msg, "search/?jql=#{escape(jql)}AND%20status%20%21%3D%20%22Signed%20Off%22", (result) ->
      if result.errors?
        return

      resultText = "I found #{result.total} issues for your search."
      if result.issues.length <= maxlist
        cb resultText
        result.issues.forEach (issue) ->
          cb issue.key + ": " + issue.fields.summary
      else
        cb resultText + " (too many to list)"

  robot.respond /(show )?watchers (for )?(\w+-[0-9]+)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    watchers msg, msg.match[3], (text) ->
      msg.send text

  robot.respond /(show )?comments (for )?(\w+-[0-9]+)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    comments msg, msg.match[3], (text) ->
      msg.send text
  
  robot.respond /search (for )?(.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return
      
    search msg, msg.match[2], (text) ->
      msg.reply text

  robot.respond /show (open issues for )?(.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    openIssues msg, msg.match[2], (text) ->
      msg.reply text
  
  robot.respond /([^\w\-]|^)(\w+-[0-9]+)(?=[^\w]|$)/ig, (msg) ->
    if msg.message.user.id is robot.name
      return

    if (ignoredusers.some (user) -> user == msg.message.user.name)
      console.log 'ignoring user due to blacklist:', msg.message.user.name
      return
   
    for matched in msg.match
      ticket = (matched.match /(\w+-[0-9]+)/)[0]
      if !recentissues.contains msg.message.user.room+ticket
        info msg, ticket, (text) ->
          msg.send text
        recentissues.add msg.message.user.room+ticket


