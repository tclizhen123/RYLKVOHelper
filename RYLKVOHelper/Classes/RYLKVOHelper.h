//
//  RYLKVOHelper.h
//  RYLKVOHelper
//
//  Created by ryan on 2020/5/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RYLKVOBlock)(NSDictionary *change);

@interface NSObject (RYLKVOHelper)

-(void ) registerWithObserver:(id )observer key:(NSString *)key block:(RYLKVOBlock )block;
-(void ) unregisterWithObserver:(id )observer key:(NSString *)key;

@end


NS_ASSUME_NONNULL_END
