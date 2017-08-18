//
//  THNFindLocalClass.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "THNFindLocalClass.h"

@implementation THNFindLocalClass

+ (NSArray *)findLocalClassWithPath:(NSString *)path subPathArray:(NSArray *)subPathArray {
    // 类信息
    NSMutableArray *classArray = [NSMutableArray array];
    // 文件名跟类信息(需要的返回参数可改成这个)
    NSMutableDictionary *fileDic = [NSMutableDictionary dictionary];
    
    for (NSString *subPath in subPathArray) {
        NSString *fileName = [subPath componentsSeparatedByString:@"/"].lastObject;
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        
        if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            continue;
        }
        
        NSError *error = nil;
        NSString *fileData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"读文件失败 error : %@", error);
            continue;
        }
        
        NSArray *lineArray = [fileData componentsSeparatedByString:@"\n"];
        for (NSString *lineString in lineArray) {
            NSString *className = [self getClassNameFromLineString:lineString];
            
            if (className) {
                // 加到类数组中
                [classArray addObject:className];
                
                // 加到字典中
                NSMutableArray *fileClassArray = fileDic[fileName];
                if (!fileClassArray) {
                    fileClassArray = [NSMutableArray array];
                    [fileDic setObject:fileClassArray forKey:fileName];
                }
                [fileClassArray addObject:className];
            }
        }
    }
    
    return classArray;
}

+ (NSString *)getClassNameFromLineString:(NSString *)line {
    
    NSString *identifier = @"@implementation";
    if (line.length < identifier.length) {
        return nil;
    }
    
    NSRange range = [line rangeOfString:identifier
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, identifier.length)];
    
    if (range.location != NSNotFound) {
        if (![line containsString:@"("]) // 忽略分类
        {
            line = [line stringByReplacingOccurrencesOfString:identifier withString:@""];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSArray *components = [line componentsSeparatedByString:@" "];
            if (components.firstObject) {
                return components.firstObject;
            }
        }
    }
    
    return nil;
}

@end
