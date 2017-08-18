//
//  THNFindAbandonedMethod.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "THNFindAbandonedMethod.h"
#import <objc/runtime.h>

extern IMP thn_cache_getImp(Class cls, SEL sel);

static void getUnusedMethodInfo(Class cls, NSMutableArray *unusedMethodArray, NSUInteger *usedMethodCount);

@implementation THNFindAbandonedMethod

+ (NSDictionary *)findAbandonedMethodWithClassArray:(NSArray *)classArray {
    
    NSMutableDictionary *classMethodDic = [NSMutableDictionary dictionary];
    for (NSString *clsString in classArray) {
        
        NSUInteger usedMethodCount = 0;
        NSMutableDictionary *unusedInfoDic = [NSMutableDictionary dictionary];
        NSMutableArray *unusedMethodArray = [NSMutableArray array];
        
        Class cls = NSClassFromString(clsString);
        Class metaCls = object_getClass(cls);
        
        // 实例方法使用信息
        getUnusedMethodInfo(cls, unusedMethodArray, &usedMethodCount);
        // 类方法使用信息
        getUnusedMethodInfo(metaCls, unusedMethodArray, &usedMethodCount);
        
        // 当usedMethodCount = 0 时，该类可以考虑删除
        [unusedInfoDic setObject:@(usedMethodCount) forKey:@"usedMethodCount"];
        [unusedInfoDic setObject:unusedMethodArray forKey:@"unusedMethodArray"];
        
        [classMethodDic setObject:unusedInfoDic forKey:clsString];
    }
    
    return classMethodDic;
}

// 在该类的方法缓存表里查询方法的使用情况，如果不在缓存中，则认为该方法未被使用过
static void getUnusedMethodInfo(Class cls,
                                NSMutableArray *unusedMethodArray,
                                NSUInteger *usedMethodCount) {
    if (!cls) return;
    
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    
    for (unsigned int index = 0; index < count; index++) {
        Method itemMethod = methods[index];
        SEL itemSel = method_getName(itemMethod);
        IMP itemImp = thn_cache_getImp(cls, itemSel);
        
        if (!itemImp) {
            NSString *itemMethodStr = NSStringFromSelector(itemSel);
            [unusedMethodArray addObject:itemMethodStr];
        } else {
            *usedMethodCount = *usedMethodCount + 1;
        }
    }
}

@end
