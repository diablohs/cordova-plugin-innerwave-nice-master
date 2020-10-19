var exec = require('cordova/exec');

NicePlugin.prototype.callPayment = function (arg0, success, error) {
    cordova.exec(success, error, 'NicePlugin', 'callPayment', [arg0]);
};

NicePlugin = new NicePlugin();
module.exports = NicePlugin;