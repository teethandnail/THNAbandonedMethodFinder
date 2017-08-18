//
//  THNClassInheritUtility.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "THNClassInheritUtility.h"
#import <objc/runtime.h>

@interface THNTreeNode : NSObject

@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSNumber *usedMethodCount;
@property (nonatomic, strong) NSMutableArray *childClsNodeArray;

@end

@implementation THNTreeNode

- (NSString *)getInheritDescInDeep:(NSUInteger)deep {
    
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n>"];
    for (NSUInteger index = 0; index < deep; index++) {
        [desc appendFormat:@"--"];
    }
    
    [desc appendString:[NSString stringWithFormat:@"%@ [用到的方法个数:%@]", self.className, self.usedMethodCount]];
    
    for (THNTreeNode *item in self.childClsNodeArray) {
        [desc appendString:[item getInheritDescInDeep:deep+1]];
    }
    
    return desc;
}

@end

@interface THNClassInheritUtility ()

@end

@implementation THNClassInheritUtility

+ (NSString *)getInheritWithClassInfoDic:(NSDictionary *)classInfoDic {
    
    // 最后得到的differentParentArray是最顶层的父类
    NSMutableArray *differentParentArray = [NSMutableArray array];
    // 用于查找class对应的node实例
    NSMutableDictionary *classToNodeDic = [NSMutableDictionary dictionary];
    
    for (NSString *className in classInfoDic.allKeys) {
        
        NSDictionary *userInfoDic = classInfoDic[className];
        NSNumber *usedMethodCount = userInfoDic[@"usedMethodCount"];
        
        THNTreeNode *node = [[THNTreeNode alloc] init];
        node.usedMethodCount = usedMethodCount;
        node.className = className;
        node.childClsNodeArray = [NSMutableArray array];
        
        [differentParentArray addObject:node];
        [classToNodeDic setObject:node forKey:className];
    }
    
    NSInteger totalCount = differentParentArray.count;
    NSInteger nextIndex = 0;
    
    while (nextIndex < totalCount) {
        THNTreeNode *currentNode = differentParentArray[nextIndex];
        NSString *className = currentNode.className;
        
        Class cls = NSClassFromString(className);
        Class superCls = [cls superclass];
        NSString *superClsStr = NSStringFromClass(superCls);
        if (superCls && superClsStr) {
            THNTreeNode *superNode = classToNodeDic[superClsStr];
            if (superNode) {
                [superNode.childClsNodeArray addObject:currentNode];
                [differentParentArray removeObject:currentNode];
                nextIndex--;
                totalCount--;
            }
        }
        
        nextIndex++;
    }
    
    NSMutableString *desc = [NSMutableString string];
    for (THNTreeNode *item in differentParentArray) {
        [desc appendString:[item getInheritDescInDeep:1]];
    }
    
    return desc;
}

@end
