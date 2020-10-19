function NicePlugin() {
    NicePlugin.prototype.ERRORS = {
        BAD_PADDING_EXCEPTION: "BAD_PADDING_EXCEPTION",
        CERTIFICATE_EXCEPTION: "CERTIFICATE_EXCEPTION",
        FINGERPRINT_CANCELLED: "FINGERPRINT_CANCELLED",
        FINGERPRINT_DATA_NOT_DELETED: "FINGERPRINT_DATA_NOT_DELETED",
        FINGERPRINT_ERROR: "FINGERPRINT_ERROR",
        FINGERPRINT_NOT_AVAILABLE: "FINGERPRINT_NOT_AVAILABLE",
        FINGERPRINT_PERMISSION_DENIED: "FINGERPRINT_PERMISSION_DENIED",
        FINGERPRINT_PERMISSION_DENIED_SHOW_REQUEST: "FINGERPRINT_PERMISSION_DENIED_SHOW_REQUEST",
        ILLEGAL_BLOCK_SIZE_EXCEPTION: "ILLEGAL_BLOCK_SIZE_EXCEPTION",
        INIT_CIPHER_FAILED: "INIT_CIPHER_FAILED",
        INVALID_ALGORITHM_PARAMETER_EXCEPTION: "INVALID_ALGORITHM_PARAMETER_EXCEPTION",
        IO_EXCEPTION: "IO_EXCEPTION",
        JSON_EXCEPTION: "JSON_EXCEPTION",
        MINIMUM_SDK: "MINIMUM_SDK",
        MISSING_ACTION_PARAMETERS: "MISSING_ACTION_PARAMETERS",
        MISSING_PARAMETERS: "MISSING_PARAMETERS",
        NO_SUCH_ALGORITHM_EXCEPTION: "NO_SUCH_ALGORITHM_EXCEPTION",
        SECURITY_EXCEPTION: "SECURITY_EXCEPTION"
    }
}

NicePlugin.prototype.callPayment = function (arg0, success, error) {
    cordova.exec(success, error, 'NicePlugin', 'callPayment', [arg0]);
};

NicePlugin = new NicePlugin();
module.exports = NicePlugin;