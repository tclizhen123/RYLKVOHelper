//
//  RYLViewController.m
//  RYLKVOHelper
//
//  Created by lizhen21 on 05/16/2020.
//  Copyright (c) 2020 lizhen21. All rights reserved.
//

#import "RYLViewController.h"
#import <RYLKVOHelper/RYLKVOHelper.h>

@interface RYLTestObject : NSObject

@property (nonatomic, copy) NSString *test;

@end

@implementation RYLTestObject

-(void ) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"observeValueForKeyPath %@ change %@", keyPath, change);
}

-(void ) dealloc{
    NSLog(@"RYLTestObject dealloc");
}

@end

@interface RYLViewController ()

@property (nonatomic ) RYLTestObject *testTarget;
@property (nonatomic ) RYLTestObject *testObserver;

@end

@implementation RYLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.testTarget = [RYLTestObject new];
    self.testObserver = [RYLTestObject new];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)destroyTarget:(id)sender {
    self.testTarget = nil;
}

- (IBAction)changeTargetProperty:(id)sender {
    
    static NSInteger kTestValue = 0;
    self.testTarget.test = [@(kTestValue ++) stringValue];
    
}

- (IBAction)destroyObserver:(id)sender {\
    self.testObserver = nil;
}

//- (IBAction)addObserver:(id)sender {
////    [self.testTarget addObserver:self.testObserver forKeyPath:@"test" options:NSKeyValueObservingOptionNew context:NULL];
//    [self.testTarget registerWithObserver:self.testObserver key:@"test" block:^(NSDictionary * _Nonnull change) {
//        NSLog(@"changed %@",change);
//    }];
//}
//
//- (IBAction)removeObserver:(id)sender {
//    [self.testTarget unregisterWithObserver:self.testObserver key:@"test"];
////    [self.testTarget removeObserver:self.testObserver forKeyPath:@"test"];
//}

- (IBAction)btn_addObserver:(id)sender {
    [self.testTarget registerWithObserver:self.testObserver key:@"test" block:^(NSDictionary * _Nonnull change) {
        NSLog(@"changed %@",change);
    }];
}

- (IBAction)btn_removeObserver:(id)sender {
    [self.testTarget unregisterWithObserver:self.testObserver key:@"test"];
}

- (IBAction)testGeekBench:(id)sender {
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    for (int i = 0; i < 10; i ++){
        [self.testTarget registerWithObserver:self.testObserver key:@"test" block:^(NSDictionary * _Nonnull change) {
            
        }];
        for (int j = 0; j < 1000; j ++){
            self.testTarget.test = [@(i + j) stringValue];
        }
        
        [self.testTarget unregisterWithObserver:self.testObserver key:@"test"];
    }
    
    NSTimeInterval use = [[NSDate date] timeIntervalSince1970] - start;
    NSLog(@"use time %@", @(use));
    
}
@end
