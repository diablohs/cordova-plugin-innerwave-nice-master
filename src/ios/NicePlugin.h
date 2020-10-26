#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

@interface NicePlugin : CDVPlugin{

}

+ (NicePlugin *) nicePlugin;
- (void)callback:(NSMutableDictionary*)value;
- (void)callPayment:(CDVInvokedUrlCommand*)command;
- (NSString *)encode:(NSString *)value;
- (NSData *)AESEncryptWithKey_A:(NSString *)key data:(NSData *)data;
- (NSString *) base64EncodeData: (NSData *) objData;
- (NSData *) SHA256Hash:(NSData *)data;
- (NSString *)hexStringForColor:(UIColor *)color;

@end