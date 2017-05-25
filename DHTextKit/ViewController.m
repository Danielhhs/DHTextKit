//
//  ViewController.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "ViewController.h"
#import "DHLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    DHLabel *label = [[DHLabel alloc] initWithFrame:CGRectMake(100, 100, 200, 100)];
    UIFont *font = [UIFont systemFontOfSize:15];
    UIColor *color = [UIColor redColor];
    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : color};
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:@"Any thing you want to saya \n and whatever you want to a work" attributes:attributes];
    label.attribtuedText = attrStr;
    [self.view addSubview:label];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
