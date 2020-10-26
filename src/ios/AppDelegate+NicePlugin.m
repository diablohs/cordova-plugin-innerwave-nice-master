#import "AppDelegate+NicePlugin.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

@implementation AppDelegate (NicePlugin)

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    
    // NSLog(@"%@", callbackIdStr);

    // CDVPluginResult* pluginResult = nil;
    NSArray *paramArray = [[url query] componentsSeparatedByString:@"&"];
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
    for (NSString *keyValuePair in paramArray) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [paramDict setObject:value forKey:key];
    }
    
    NSLog(@"openUrl 진입");
    NSLog(@"OTC:%@", paramDict[@"OTC"]);
    NSLog(@"MEMBER_ID:%@", paramDict[@"MEMBER_ID"]);
    NSLog(@"CARD_COMP_CODE:%@", paramDict[@"CARD_COMP_CODE"]);
    NSLog(@"SIGN_IMG:%@", paramDict[@"SIGN_IMG"]);
    NSLog(@"ID_CD:%@", paramDict[@"ID_CD"]);

    // NSDictionary *resultDict = [[NSDictionary alloc] init];
    // [resultDict setValue:[NSNumber numberWithBool:TRUE] forKey:@"result"];
    // [resultDict setValue:@"test message" forKey:@"message"];
    // NSData* jsonData = [NSJSONSerialization dataWithJSONObject:resultDict options:NSJSONWritingPrettyPrinted error:nil];
    // NSString* jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    // NSLog(@"jsonDataStr: %@", jsonData);

    [NicePlugin.nicePlugin callback:paramDict];

    return YES;
}

@end