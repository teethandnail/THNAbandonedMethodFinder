//
//  THNTreeNode.h
//  Cashier
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THNTreeNode : NSObject

@property (nonatomic, weak) THNTreeNode *parentNode;

@property (nonatomic, copy) NSString *className;

@property (nonatomic, copy) NSNumber *usedMethodCount;

@property (nonatomic, strong) NSMutableArray *childClsNodeArray;

- (NSString *)getInheritDescInDeep:(NSUInteger)deep;

@end
