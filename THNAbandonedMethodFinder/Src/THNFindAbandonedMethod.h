//
//  THNFindAbandonedMethod.h
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THNFindAbandonedMethod : NSObject

/**
 * 返回每个类的实例方法、类方法的使用情况
 *
 @param classArray 需要查询的类数组
 @return 类的使用信息，当usedMethodCount = 0时，说明该类未被使用，可考虑删除
 */
+ (NSDictionary *)findAbandonedMethodWithClassArray:(NSArray *)classArray;

@end
