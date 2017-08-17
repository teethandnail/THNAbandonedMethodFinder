//
//  TestModel2.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "TestModel2.h"

@implementation TestModel2

- (void)p_func1 {
    NSLog(@"%@ p_func1", NSStringFromClass([self class]));
}

+ (void)b_func1 {
    NSLog(@"%@ p_func2", NSStringFromClass([self class]));
}


@end
