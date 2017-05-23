//
//  ViewController.m
//  TWRichTextEditorDemo
//
//  Created by luomeng on 2017/5/23.
//  Copyright © 2017年 XRY. All rights reserved.
//

#import "ViewController.h"
#import "TWDemoViewController.h"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_push:(id)sender {
    
    TWDemoViewController *demo = [[TWDemoViewController alloc] init];
    [self.navigationController pushViewController:demo animated:YES];

}

@end
