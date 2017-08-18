//
//  TestModel1.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "TestModel1.h"

@implementation TestModel1

- (void)p_func1 {
    NSLog(@"%@ p_func1 running", NSStringFromClass([self class]));
}

- (void)p_func2 {
    NSLog(@"%@ p_func2 running", NSStringFromClass([self class]));
}

+ (void)b_func1 {
    NSLog(@"%@ b_func1 running", NSStringFromClass([self class]));
}

+ (void)b_func2 {
    NSLog(@"%@ b_func2 running", NSStringFromClass([self class]));
}

@end
