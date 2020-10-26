/********* NicePlugin.m Cordova Plugin Implementation *******/
#import "NicePlugin.h"
#import "AppDelegate+NicePlugin.h"
#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

@implementation NicePlugin

static const char _base64EncodingTable[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static NSString *callbackIdStr;
static NSString *encKey;
static NicePlugin *nicePluginInstance;

+ (NicePlugin *) nicePlugin {
    return nicePluginInstance;
}

- (void)callback:(NSMutableDictionary*)value
{
    CDVPluginResult* pluginResult = nil;

    NSLog(@"nice앱 리턴 : %@", value[@"resultCode"]);

    if (value != nil && ([value[@"resultCode"]  isEqual: @"-1"] || [value[@"resultCode"]  isEqual: @"0000"])) {     //결제성공
        NSMutableDictionary *tempDict = [[NSDictionary alloc] init];
        [tempDict setValue:value[@"resultCode"] forKey:@"resultKey"];
        [tempDict setValue:value[@"OTC"] forKey:@"otc"];
        [tempDict setValue:value[@"MEMBER_ID"] forKey:@"memberId"];
        [tempDict setValue:value[@"CARD_COMP_CODE"] forKey:@"cardCompCode"];
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:tempDict options:NSJSONWritingPrettyPrinted error:nil];
        NSString* jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonDataStr];
    } else {    //결제실패
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
        [tempDict setValue:value[@"resultCode"] forKey:@"resultCode"];
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:tempDict options:NSJSONWritingPrettyPrinted error:nil];
        NSString* jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonDataStr];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackIdStr];
}

- (NSString *)encode:(NSString *)value 
{
    if ([value length] == 0) {
        return @"";
    }
    
    //현재 시간을 문자열에 추가.
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HHmmss";
    NSString *dateString = [df stringFromDate:[NSDate date]];
    
    value = [value stringByAppendingString:dateString];
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    data = [self AESEncryptWithKey_A:encKey data:data];
    NSString *encodedData = [self base64EncodeData:data];
    return encodedData;
}

- (NSData *)AESEncryptWithKey_A:(NSString *)key data:(NSData *)data
{
    //*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:
    // 파라메터의 key 값 길이가 32 바이트이면 kCCKeySizeAES256 로 설정
    // 파라메터의 key 값 길이가 16 바이트이면 kCCKeySizeAES128 로 설정
    //*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:*:
    
    // 'key' should be 32 bytes for AES256,
    // 16 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 /*kCCKeySizeAES128*/ + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // insert key in char array
    BOOL bRet = [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    if( ! bRet )    return nil;
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    
    CCCryptorStatus cryptStatus = 0;
    if([key length] == 32){
        // the encryption method, use always same attributes in android and iPhone (f.e. PKCS7Padding)
        cryptStatus = CCCrypt(kCCEncrypt,
                              kCCAlgorithmAES,
                              kCCOptionECBMode | kCCOptionPKCS7Padding,
                              keyPtr,
                              kCCKeySizeAES256,     /*kCCKeySizeAES128,*/
                              NULL                      /* initialization vector (optional) */,
                              [data bytes], dataLength, /* input */
                              buffer, bufferSize,       /* output */
                              &numBytesEncrypted);
        
    }else{
        cryptStatus = CCCrypt(kCCEncrypt,
                              kCCAlgorithmAES,
                              kCCOptionECBMode | kCCOptionPKCS7Padding,
                              keyPtr,
                              kCCKeySizeAES128,     /*kCCKeySizeAES128,*/
                              NULL                      /* initialization vector (optional) */,
                              [data bytes], dataLength, /* input */
                              buffer, bufferSize,       /* output */
                              &numBytesEncrypted);
    }
    
    
    if (cryptStatus == kCCSuccess) {
        
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

- (NSString *) base64EncodeData: (NSData *) objData
{
    const unsigned char * objRawData = (unsigned char *)[objData bytes];
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    NSInteger intLength = [objData length];
    if (intLength == 0) return nil;
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    NSString *strToReturn = [[NSString alloc] initWithBytesNoCopy:strResult length:objPointer - strResult encoding:NSASCIIStringEncoding freeWhenDone:YES];
    return strToReturn;
}

- (NSData *) SHA256Hash:(NSData *)data
{
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    (void) CC_SHA256( [data bytes], (CC_LONG)[data length], hash );
    return ( [NSData dataWithBytes: hash length: CC_SHA256_DIGEST_LENGTH] );
}

- (NSString *)hexStringForColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    NSString *hexString=[NSString stringWithFormat:@"%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
    return hexString;
}

- (void)callPayment:(CDVInvokedUrlCommand*)command
{
    // AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    // appDelegate.nicePlugin = self;
    // [NicePlugin nicePlugin].delegate = self;
    // nicePlugin.delegate = self;
    nicePluginInstance = self;

    NSString* params = [command.arguments objectAtIndex:0];
    NSData *jsonData = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];

    encKey = [dict objectForKey:@"encryptKey"];
    callbackIdStr = command.callbackId;
    NSLog(@"%@", params);
    NSLog(@"%@", command);

    //파트너 코드
    NSString *partner_cd = [dict objectForKey:@"partnerCd"];
    //파트너 아이디
    NSString *partner_id = [dict objectForKey:@"partnerId"];
    NSString *encoded_partner_id = [self encode:partner_id];
    // //쿠폰 이름
    // NSString *encoded_partner_coupon_name = [self encode:@"테스트 쿠폰"];
    // //쿠폰 번호
    // NSString *encoded_partner_coupon_num = [self encode:@"516851682234"];
    // //멤버십 이름
    // NSString *encoded_partner_membership_name = [self encode:@"테스트 멤버십"];
    // //멤버십 번호
    // NSString *encoded_partner_membership_card_num = [self encode:@"9410107100001234"];
    //제휴사 사업자 번호
    NSString *merchant_cd = [dict objectForKey:@"merchantCd"];
    NSString *encoded_merchant_cd = [self encode:merchant_cd];
    //승인요청 VAN ID
    NSString *van_id = [dict objectForKey:@"vanId"];
    NSString *encoded_van_id = [self encode:van_id];
    //프로세스 구분 코드
    NSString *pay_order = @"A";//@"QOMC";
    //가맹점 색상
    NSString *partner_rgb = [self hexStringForColor:[UIColor greenColor]];
    //해시 값
    NSData *partner_cd_id = [[NSString stringWithFormat:@"%@%@", partner_cd, partner_id] dataUsingEncoding:NSASCIIStringEncoding];
    NSString *h = [[NSString alloc] initWithData:[self SHA256Hash:partner_cd_id] encoding:NSASCIIStringEncoding];
    NSString *encoded_h = [self encode:h];
    //결제 가격
    NSString *payPrice = [dict objectForKey:@"payPrice"];
    //5만원 이상시 서명여부 pass_sign이 true이면 서명 안함
    NSString *pass_sign = @"true";//@"false"
    //결제앱 구분코드
    NSString *id_cd = @"01";
    //거래 일련번호
    NSString *tx_id = @"123456789";
    //가맹점 스키마
    NSString *scheme = @"patientcenteredmobile://openURL";
    
    //앱투앱 파라미터
    NSMutableString *app_to_app_url = [NSMutableString stringWithFormat:@"niceappcard://%@?appver=5&apiver=2", @"payment"];
    [app_to_app_url appendFormat:@"&partner_cd=%@", partner_cd];
    [app_to_app_url appendFormat:@"&partner_id=%@", encoded_partner_id];
    // [app_to_app_url appendFormat:@"&partner_coupon_name=%@", encoded_partner_coupon_name];
    // [app_to_app_url appendFormat:@"&partner_coupon_num=%@", encoded_partner_coupon_num];
    // [app_to_app_url appendFormat:@"&partner_membership_name=%@", encoded_partner_membership_name];
    // [app_to_app_url appendFormat:@"&partner_membership_card_num=%@", encoded_partner_membership_card_num];
    [app_to_app_url appendFormat:@"&merchant_cd=%@", encoded_merchant_cd];
    [app_to_app_url appendFormat:@"&van_id=%@", encoded_van_id];
    [app_to_app_url appendFormat:@"&pay_order=%@", pay_order];
    [app_to_app_url appendFormat:@"&partner_rgb=%@", partner_rgb];
    [app_to_app_url appendFormat:@"&h=%@", encoded_h];
    [app_to_app_url appendFormat:@"&payPrice=%@", payPrice];
    [app_to_app_url appendFormat:@"&pass_sign=%@", pass_sign];
    [app_to_app_url appendFormat:@"&id_cd=%@", id_cd];
    [app_to_app_url appendFormat:@"&tx_id=%@", tx_id];
    [app_to_app_url appendFormat:@"&callback=%@", scheme];
    
    NSString *appcard_appstore_url = @"https://itunes.apple.com/kr/app/apple-store/id1146369440?mt=8";
    NSString *appcard_scheme = @"niceappcard://";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appcard_scheme]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:app_to_app_url]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appcard_appstore_url]];
    }
}

@end
