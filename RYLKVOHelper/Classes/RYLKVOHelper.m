//
//  RYLKVOHelper.m
//  RYLKVOHelper
//
//  Created by ryan on 2020/5/16.
//

#import "RYLKVOHelper.h"
#import <objc/runtime.h>
#import <pthread.h>
#import <os/lock.h>

typedef void(^RYLKVOBlock)(NSDictionary *change);

@interface _RYLKVOEntry : NSObject {
    dispatch_queue_t _rwqueue;
}

@property (nonatomic ) NSMapTable *mapTable;
@property (nonatomic, weak) id parent;

@end

@implementation _RYLKVOEntry

-(instancetype ) initWithParent:(id )parent{
    if (self = [super init]){
        
        _rwqueue = dispatch_queue_create("com.ryl.kvo.helper.queue", DISPATCH_QUEUE_CONCURRENT);
        self.mapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsCopyIn capacity:3];
        self.parent = parent;
    }
    return self;
}

-(BOOL ) _isObserverExistWithTarget:(id )target{
    id retval = [self.mapTable objectForKey:target];
    
    return retval != nil;
}

-(void ) _registerWithTarget:(id )target key:(NSString *)key block:(RYLKVOBlock )block{
    
    __weak typeof (self) wself = self;
    dispatch_barrier_async(_rwqueue, ^{

        __strong typeof (wself) sself = wself;

        if (![sself _isObserverExistWithTarget:target]){
            [target addObserver:sself forKeyPath:key options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        }

        [sself editMapTableWithTarget:target block:^(NSMutableDictionary *dict) {
            [dict setObject:block forKey:key];
        }];

    });
    
}

-(void ) _unregisterWithTarget:(id )target key:(NSString *)key {
    
    __weak typeof (self) wself = self;
    dispatch_barrier_async(_rwqueue, ^{
        __strong typeof (wself) sself = wself;
    
        if ([sself _isObserverExistWithTarget:target]) {
            NSDictionary *dict = [sself.mapTable objectForKey:target];
            if (dict == nil || dict.allValues.count == 0){

                [target removeObserver:sself forKeyPath:key];
                [sself.mapTable removeObjectForKey:target];

            } else {

                [sself editMapTableWithTarget:target block:^(NSMutableDictionary *dict) {
                    [dict removeObjectForKey:key];
                }];

            }

        }
    });
}

-(void ) editMapTableWithTarget:(id )target block:(void (^) (NSMutableDictionary *dict))block{
    
    NSMutableDictionary *keyBlockDict = [([self.mapTable objectForKey:target] ?: @{}) mutableCopy];
    if (block) block(keyBlockDict);
    [self.mapTable setObject:[keyBlockDict copy] forKey:target];
    
}

-(void ) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    __weak typeof (self) wself = self;
    dispatch_async(_rwqueue, ^{
        __strong typeof (wself) sself = wself;
        NSDictionary *keyBlock = [sself.mapTable objectForKey:object];
        if (keyBlock){
            RYLKVOBlock block = keyBlock[keyPath];
            if (block) block(change);
        }
    });

}

-(void ) dealloc{
    dispatch_barrier_sync(_rwqueue, ^{
        for (id target in self.mapTable.keyEnumerator){
            NSDictionary *dict = [self.mapTable objectForKey:target];
            for (NSString *key in dict.allKeys.objectEnumerator){
                [target removeObserver:self forKeyPath:key];
            }
        }
    });
}

@end

@interface NSObject (_RYLKVOEntryGetter)

-(_RYLKVOEntry *) _getKVOEntry;
-(void ) _setKVOEntry:(_RYLKVOEntry *)entry;

@end


@implementation NSObject (RYLKVOHelper)

-(void ) registerWithObserver:(id )observer key:(NSString *)key block:(RYLKVOBlock )block{
    
    _RYLKVOEntry *entry;
    @synchronized (self) {
        entry = [observer _getKVOEntry];
        if (!entry){
            entry = [[_RYLKVOEntry alloc] initWithParent:observer];
            [observer _setKVOEntry:entry];
        }
        
    }
    
    [entry _registerWithTarget:self key:key block:block];
    
}

-(void ) unregisterWithObserver:(id )observer key:(NSString *)key{
    
    @synchronized (self) {
        _RYLKVOEntry *entry = [observer _getKVOEntry];
        if (entry) [entry _unregisterWithTarget:self key:key];
    }
    
}

@end

@implementation NSObject (_RYLKVOEntryGetter)

-(_RYLKVOEntry *) _getKVOEntry{
    return objc_getAssociatedObject(self, @selector(_getKVOEntry));
}

-(void ) _setKVOEntry:(_RYLKVOEntry *)entry{
    objc_setAssociatedObject(self, @selector(_getKVOEntry), entry, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
