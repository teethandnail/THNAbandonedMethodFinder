//
//  ViewController.m
//  iOSDemo
//
//  Created by ZhangHonglin on 2017/8/18.
//  Copyright © 2017年 h. All rights reserved.
//

#import "ViewController.h"
#import "TestModel1.h"
#import "THNFindAbandonedMethod.h"
#import "THNClassInheritUtility.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)clickAction:(id)sender {
    
    // 让TestModel1执行几个方法，看是否能找出该类的方法废弃情况
    TestModel1 *model1 = [[TestModel1 alloc] init];
    [model1 p_func1];
    [TestModel1 b_func1];
    
    // 工程目录下的类，通过THNFindLocalClass分析活动
    NSArray *classArray = @[@"AppDelegate",
                            @"THNTreeNode",
                            @"THNClassInheritUtility",
                            @"THNFindAbandonedMethod",
                            @"TestModel1",
                            @"TestModel2",
                            @"TestModel3",
                            @"ViewController",];
    
    // 分析出各类不使用的method
    NSDictionary *abandonedClassDic = [THNFindAbandonedMethod findAbandonedMethodWithClassArray:classArray];
    // 获取类之间的继承关系及类里有多少个使用的方法，当usedMethodCount = 0时，可考虑删除该类
    NSString *inheritDesc = [THNClassInheritUtility getInheritWithClassInfoDic:abandonedClassDic];
    
    NSLog(@"\n\n============= 废弃函数统计情况 ===============\n%@", abandonedClassDic);
    NSLog(@"\n\n=========== 类使用情况及继承关系 ==============\n%@", inheritDesc);
}

@end
