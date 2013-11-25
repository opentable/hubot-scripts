// Description:
//   Pull yourself.
//   Run a git-pull on the directory hubot is running in and then restart hubot
//   Assumes that you have an up-script to restart hubot after it kills itself
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot tug - git-pull yourself and then die (assumes an up-script will restart)

var cp = require('child_process'),
    logger;

module.exports = function(robot){
    logger = robot.logger;

    robot.respond(/tug$/i, function(msg){
        pull(msg, function(){
            cleanup(function(){
                sepukku(msg);
            });
        });
    });
};

var pull = function(msg, callback){
    var gitpull = cp.spawn('git', ['pull']);

    gitpull.stdout.on('data', function (data) {
        logger.debug('[git-pull] ' + data);
    });

    gitpull.stderr.on('data', function (data) {
        logger.error('[git-pull] err: ' + data);
    });

    gitpull.on('close', function (code) {
        logger.info('[git-pull] updated repo, exited with code: ' + code);
        if(code !== 0){
            msg.send('Could not update hubot, git-pull exited with code ' + code);
        }
        else{
            callback()
        }
    });
},

cleanup = function(callback){
    var rm = cp.spawn('rm', ['-rf', process.cwd() + '/node_modules/hubot-scripts']);

    rm.stdout.on('data', function (data) {
        logger.debug('[rm] ' + data);
    });

    rm.stderr.on('data', function (data) {
        logger.error('[rm] err: ' + data);
    });

    rm.on('close', function (code) {
        logger.info('[rm] deleted hubot-scripts directory');
        if(code !== 0){
            msg.send('Could not update hubot, rm exited with code ' + code);
        }
        else{
            callback()
        }
    });
},

sepukku = function(msg){
    msg.send('Goodbye, cruel world!');
    process.exit(0);
};