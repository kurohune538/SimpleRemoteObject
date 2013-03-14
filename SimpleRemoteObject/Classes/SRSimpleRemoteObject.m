//
//  SRSimpleRemoteObject.m
//  SRSimpleRemoteObject
//
//  Created by Hal Seki on 2/22/13.
//  Copyright (c) 2013 Georepublic. All rights reserved.
//

#import "SRSimpleRemoteObject.h"
#import "AFNetworking.h"
#import "NSObject+SRPropertyUtil.h"


@implementation SRSimpleRemoteObject

/**
 // read data from specified URI
 */
+(void)fetchAsync:(SRFetchCompletionBlock)completionBlock{
    
    NSString *strurl = [NSString stringWithFormat:@"%@%@", [SRRemoteConfig defaultConfig].baseurl, [[self class] performSelector:@selector(representUrl)]];
    [[self class] performSelector:@selector(fetchURL:async:) withObject:strurl withObject:completionBlock];
}
/**
 // read data from specified URI with parameters
 */
+(void)fetchAsyncWithParams:(NSDictionary *)params async:(SRFetchCompletionBlock)completionBlock{
    NSString *path = [[self class] performSelector:@selector(representUrl)];
    for (NSString *key in [params allKeys]){
        if ([path rangeOfString:@"?"].location == NSNotFound){
            path = [path stringByAppendingFormat:@"?%@=%@", key, [params objectForKey:key]];
        }else{
            path = [path stringByAppendingFormat:@"&%@=%@", key, [params objectForKey:key]];
        }
    }
    
    NSString *strurl = [NSString stringWithFormat:@"%@%@", [SRRemoteConfig defaultConfig].baseurl, path];
    NSLog(@"call:%@", strurl);
    [[self class] performSelector:@selector(fetchURL:async:) withObject:strurl withObject:completionBlock];
}
+(void)fetchURL:(NSString *)strurl async:(SRFetchCompletionBlock)completionBlock{
    NSURL *url = [NSURL URLWithString:strurl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"App.net Global Stream: %@", JSON);
        NSString *key = [[self class] performSelector:@selector(resultKey)];
        NSArray *ret = nil;
        if (key){
            NSArray *obj = nil;
            if ([[JSON valueForKeyPath:key] isKindOfClass:[NSArray class]]){
                obj = [JSON valueForKeyPath:key];
            }else{
                obj = [NSArray arrayWithObject:[JSON valueForKeyPath:key]];
            }
            ret = [[self class] parseJSONArray:obj];
        }else{
            if ([JSON isKindOfClass:[NSArray class]]){
                ret = [[self class] parseJSONArray:JSON];
            }else{
                ret = [[self class] parseJSONArray:[NSArray arrayWithObject:JSON]];
            }
        }
        completionBlock(ret,nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"App.net Error: %@", [error localizedDescription]);
        completionBlock(nil,error);
    }];
    [operation start];
    
}
#pragma mark -
#pragma mark internal method
/**
 // parse JSONArray and create class instance
 */
+(NSArray *)parseJSONArray:(NSArray *)array{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSDictionary *dict in array){
        id obj = [[[self class] alloc] init];
        [obj performSelector:@selector(setPropertiesUsingRemoteDictionary:) withObject:dict];
        [ret addObject:obj];
    }
    return [[NSArray alloc] initWithArray:ret];
}
- (void) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
    if ([dict objectForKey:@"id"]){
        self.remoteId = [dict objectForKey:@"id"];
    }
    NSDictionary *props = [[self class] properties];
    for (NSString *key in [props allKeys]){
        NSLog(@"key:%@", key);
        [self parseObject:[dict objectForKey:key] ForKey:key];
    }
    
}

#pragma mark -
#pragma mark below methods shoul be doverride in a subclass
+(NSString *)representUrl{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
+(NSString *)resultKey{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
// optional
-(void)parseObject:(id)object ForKey:(NSString *)key{
    if (object){
        [self setValue:object forKey:key];
    }
}

@end
