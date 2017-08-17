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

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)clickAction:(id)sender {
    
    // 让TestModel1执行几个方法，看是否能找出该类的方法废弃情况
    TestModel1 *model1 = [[TestModel1 alloc] init];
    [model1 p_func1];
    [TestModel1 b_func1];
    
    NSString *path = @"/Users/HongLin/Documents/SVN_IOS/Git_Pod/Personal_Git/THNAbandonedMethodFinder/THNAbandonedMethodFinder";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    // 找出本地的.m 文件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[c] '.m'"];
    NSArray *filterArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSArray *subPathArray = [filterArray filteredArrayUsingPredicate:predicate];
    
    // 此方法用于分析工程目录下有多少个类
    NSArray *classArray = [THNFindLocalClass findLocalClassWithPath:path subPathArray:subPathArray];
    
    // 此方法单独集成进iOS工程里，入参传入上面方法找出的类数组，跑完app的所有功能后，触发此方法，分析出method废弃数据
    NSDictionary *abandonedDic = [THNFindAbandonedMethod findAbandonedMethodWithClassArray:classArray];
    
    NSLog(@"%@", abandonedDic);
}

@end
