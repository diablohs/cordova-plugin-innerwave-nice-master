var exec = require('cordova/exec');

exports.callPayment = function (arg0, success, error) {
    exec(success, error, 'NicePlugin', 'callPayment', [arg0]);
};
