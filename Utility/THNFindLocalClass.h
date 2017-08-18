//
//  THNFindLocalClass.h
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THNFindLocalClass : NSObject

/**
 * 分析工程目录下的.m文件，找出所有的类
 *
 @param path 工程主目录
 @param subPathArray .m的路径数组
 @return 类数组
 */
+ (NSArray *)findLocalClassWithPath:(NSString *)path subPathArray:(NSArray *)subPathArray;

@end
