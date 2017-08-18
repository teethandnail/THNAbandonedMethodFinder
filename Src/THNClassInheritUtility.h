//
//  THNClassInheritUtility.h
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THNClassInheritUtility : NSObject

/**
 * 获取类的继承关系，及继承链下的方法使用情况
 *
 * @param classInfoDic 需分析的类
 * @return 结果
 */
+ (NSString *)getInheritWithClassInfoDic:(NSDictionary *)classInfoDic;

@end
