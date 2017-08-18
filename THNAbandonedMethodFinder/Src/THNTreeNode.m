//
//  THNTreeNode.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "THNTreeNode.h"

@implementation THNTreeNode

- (NSString *)getInheritDescInDeep:(NSUInteger)deep {
    
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n"];
    for (NSUInteger index = 0; index < deep; index++) {
        [desc appendFormat:@"--"];
    }
    
    [desc appendString:[NSString stringWithFormat:@"%@ [usedCount:%@]", self.className, self.usedMethodCount]];
    
    for (THNTreeNode *item in self.childClsNodeArray) {
        [desc appendString:[item getInheritDescInDeep:deep+1]];
    }
    
    return desc;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ [usedCount:%@] ,sub class {%@}", self.className, self.usedMethodCount ,self. childClsNodeArray];
}
@end
