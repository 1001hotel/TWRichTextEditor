//
//  ZSSDemoViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/29/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import "ZSSDemoViewController.h"
#import "ZSSDemoPickerViewController.h"


#import "DemoModalViewController.h"


@interface ZSSDemoViewController ()

@end

@implementation ZSSDemoViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Standard";
    
    //Set Custom CSS
    NSString *customCSS = @"";
    [self setCSS:customCSS];
    
    self.alwaysShowToolbar = YES;
    self.receiveEditorDidChangeEvents = NO;
    
    // Export HTML
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Export" style:UIBarButtonItemStylePlain target:self action:@selector(exportHTML)];
    
    // HTML Content to set in the editor
    NSString *html =     @"<div style=\"text-align: center;\"><br /></div><div style=\"text-align: right;\"><span style=\"color: rgb(231, 0, 18);\"><i>如何让你遇见我&nbsp;</i></span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(243, 153, 0);\">在我最美丽的时刻&nbsp;</span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(247, 239, 20);\">为这</span>&nbsp;</div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center;\"><span style=\"color: rgb(34, 173, 56);\">我已在佛前求了五百年</span>&nbsp;</div><div style=\"text-align: center;\"><br /></div><div style=\"text-align\" :=\"\" center; \"=\" \"><span style=\"color: rgb(3, 161, 233); \">求佛让我们结一段尘缘&nbsp;</span></div><div style=\"text-align: center; \"><span style=\"color: rgb(24, 28, 98); \"><br /></span></div><div style=\"text-align: center; \"><span style=\"color:rgb(24, 28, 98); \">佛於是把我化做的就是马赛克一棵树&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(147, 8, 131); \">长在你必经的阶段基督教路旁&nbsp;</span></div><div style=\"text-align: center;\"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(231, 0, 18); \">阳光男主角色即是空下</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(149, 96, 52);\">慎重地开好时机sjsk满了花</span>&nbsp;你上课打瞌睡</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(106, 56, 6); \">朵朵今生今世看都是我前世的盼望就大哭大哭&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center;\">当你今生今世看书看看书走近&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(89, 88, 88); \">请你细尼山萨满听</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(137, 137, 137);\">那颤抖就睡觉睡觉睡觉的叶</span>&nbsp;</div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(202, 202, 203); \">是我等待的热情&nbsp;</span></div><div style=\"text-align: center; \"><span style=\"color: rgb(240, 240, 240); \"><br /></span></div><div style=\"text-align:center; \"><span style=\"color: rgb(240, 240, 240); \">而当你终於无视地走过&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(231, 0, 18); \">在你身后落了一地的&nbsp;</span></div><div style=\"text-align:center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(137, 137, 137); \">朋友啊</span>&nbsp;</div><div style=\"text-align: center; \"><span style=\"color: rgb(202, 202, 203); \"><br /></span></div><div style=\"text-align: center;\"><span style=\"color: rgb(202, 202, 203); \">那不是花瓣&nbsp;</span></div><div style=\"text-align: center; \"><br /></div><div style=\"text-align: center; \"><span style=\"color: rgb(240, 240, 240); \">那是我凋零的心</span></div>";
    //    @"<div class='test'></div><!-- This is an HTML comment -->"
    //    "<p>This is a test of the <strong>ZSSRichTextEditor</strong> by <a title=\"Zed Said\" href=\"http://www.zedsaid.com\">Zed Said Studio</a></p>";
    
    // Set the base URL if you would like to use relative links, such as to images.
    self.baseURL = [NSURL URLWithString:@"http://www.zedsaid.com"];
    self.shouldShowKeyboard = YES;
    // Set the HTML contents of the editor
    [self setPlaceholder:@"请输入内容(不超过1000字)"];
    
    [self setHTML:html];
    
}


- (void)showInsertURLAlternatePicker {
    
    [self dismissAlertView];
    
    ZSSDemoPickerViewController *picker = [[ZSSDemoPickerViewController alloc] init];
    picker.demoView = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
    
}


- (void)showInsertImageAlternatePicker {
    
    [self dismissAlertView];
    
    ZSSDemoPickerViewController *picker = [[ZSSDemoPickerViewController alloc] init];
    picker.demoView = self;
    picker.isInsertImagePicker = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
    
}


- (void)exportHTML {
    
    NSLog(@"%@", [self getHTML]);
    
}

- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html {
    
    NSLog(@"Text Has Changed: %@", text);
    
    NSLog(@"HTML Has Changed: %@", html);
    
}

- (void)hashtagRecognizedWithWord:(NSString *)word {
    
    NSLog(@"Hashtag has been recognized: %@", word);
    
}

- (void)mentionRecognizedWithWord:(NSString *)word {
    
    NSLog(@"Mention has been recognized: %@", word);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
