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
    
    TestModel1 *model1 = [[TestModel1 alloc] init];
    [model1 p_func1];
    [TestModel1 b_func1];

    // 让TestModel1执行几个方法，看是否能找出该类的方法废弃情况
    NSString *path = @"/Users/HongLin/Documents/SVN_IOS/Git_Pod/Personal_Git/THNAbandonedMethodFinder/THNAbandonedMethodFinder";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    // 找出本地的.m 文件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[c] '.m'"];
    NSArray *filterArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSArray *subPathArray = [filterArray filteredArrayUsingPredicate:predicate];
    
    // 分析工程目录下有多少个类
    NSArray *classArray = [THNFindLocalClass findLocalClassWithPath:path subPathArray:subPathArray];
    
    // 此方法单独集成进iOS工程里，入参传入上面方法找出的类数组，跑完app的所有功能后，触发此方法，分析出method废弃数据
    NSDictionary *abandonedClassDic = [THNFindAbandonedMethod findAbandonedMethodWithClassArray:classArray];
    // 
    NSString *inheritDesc = [THNClassInheritUtility getInheritWithClassInfoDic:abandonedClassDic];
    
    NSLog(@"\n\n============= 废弃函数统计情况 ===============\n%@", abandonedClassDic);
    NSLog(@"\n\n=========== 类使用情况及继承关系 ==============\n%@", inheritDesc);
}

@end
