//
//  ViewController.m
//  THNAbandonedMethodFinder
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 h. All rights reserved.
//

#import "ViewController.h"
#import "TestModel1.h"
#import "THNFindLocalClass.h"
#import "THNFindAbandonedMethod.h"
#import "THNClassInheritUtility.h"
#import <objc/runtime.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)clickAction:(id)sender {
    
    NSString *path = @"/Users/HongLin/Documents/SVN_IOS/Git_Pod/Personal_Git/THNAbandonedMethodFinder/iOSDemo";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"目录不存在");
        return;
    }
    
    // 找出本地的.m 文件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[c] '.m'"];
    NSArray *filterArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSArray *subPathArray = [filterArray filteredArrayUsingPredicate:predicate];
    
    // 分析工程目录下有多少个类
    NSArray *classArray = [THNFindLocalClass findLocalClassWithPath:path subPathArray:subPathArray];
    NSLog(@"\n\n============= 目录下的类有 ===============\n%@", classArray);
    // 再把classArray当做入参数，传给findAbandonedMethodWithClassArray:方法，供分析
}

@end
