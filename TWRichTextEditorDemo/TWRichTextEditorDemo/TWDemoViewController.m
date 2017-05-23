//
//  TWDemoViewController.m
//  TWRichTextEditorDemo
//
//  Created by luomeng on 2017/5/23.
//  Copyright © 2017年 XRY. All rights reserved.
//

#import "TWDemoViewController.h"

@interface TWDemoViewController ()

@end

@implementation TWDemoViewController


#pragma mark -
#pragma mark - lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Test";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //Set Custom CSS
    NSString *customCSS = @"";
    [self setCSS:customCSS];
    
    self.alwaysShowToolbar = YES;
    self.receiveEditorDidChangeEvents = NO;
    
    // Export HTML
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Export" style:UIBarButtonItemStylePlain target:self action:@selector(exportHTML)];
    
    // HTML Content to set in the editor
    NSString *html =     @"<div style=\"text-align: center;\"><br /></div><div style=\"text-align: right;\"><span style=\"color: rgb(231, 0, 18);\"><i>如何让你遇见我&nbsp;</i></span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(243, 153, 0);\">在我最美丽的时刻&nbsp;</span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(247, 239, 20);\">为这</span>&nbsp;</div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(34, 173, 56);\">我已在佛前求了五百年</span>&nbsp;</div><div style=\"text-align: center;\"><br /></div><div style=\"text-align\" :=\"\" center; \"=\" \"><span style=\"color: rgb(3, 161, 233); \">求佛让我们结一段尘缘&nbsp;</span></div><div style=\"text-align: center; \"><span style=\"color: rgb(24, 28, 98); \"><br /></span></div><div style=\"text-align: center; \"><span style=\"color:rgb(24, 28, 98); \">佛於是把我化做的就是马赛克一棵树&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(147, 8, 131); \">长在你必经的阶段基督教路旁&nbsp;</span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(231, 0, 18); \">阳光男主角色即是空下</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(149, 96, 52);\">慎重地开好时机sjsk满了花</span>&nbsp;你上课打瞌睡</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(106, 56, 6); \">朵朵今生今世看都是我前世的盼望就大哭大哭&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center;\">当你今生今世看书看看书走近&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(89, 88, 88); \">请你细尼山萨满听</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(137, 137, 137);\">那颤抖就睡觉睡觉睡觉的叶</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(202, 202, 203); \">是我等待的热情&nbsp;</span></div><div style=\"text-align: center; \"><span style=\"color: rgb(240, 240, 240); \"><br /></span></div><div style=\"text-align:center; \"><span style=\"color: rgb(240, 240, 240); \">而当你终於无视地走过&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(231, 0, 18); \">在你身后落了一地的&nbsp;</span></div><div style=\"text-align:center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(137, 137, 137); \">朋友啊</span>&nbsp;</div><div style=\"text-align: center; \"><span style=\"color: rgb(202, 202, 203); \"><br /></span></div><div style=\"text-align: center;\"><span style=\"color: rgb(202, 202, 203); \">那不是花瓣&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(240, 240, 240); \">那是我凋零的心</span></div>";
    
    self.shouldShowKeyboard = YES;
    // Set the HTML contents of the editor
    [self setPlaceholder:@"请输入内容(不超过1000字)"];
    
    [self setHTML:html];
    // Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)exportHTML {
    
    NSLog(@"%@", [self getHTML]);
    
}

@end
