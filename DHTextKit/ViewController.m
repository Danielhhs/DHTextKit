//
//  ViewController.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "ViewController.h"
#import "DHLabel.h"
#import "NSAttributedString+DHText.h"

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
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"Any thing you want to saya" attributes:attributes];
    NSAttributedString *attachment = [NSAttributedString dh_attachmentStringWithContent:[UIImage imageNamed:@"Delete.png"] contentMode:UIViewContentModeScaleToFill attachmentSize:CGSizeMake(50, 50) alignToFont:font verticalAlignment:DHTextVerticalAlignmentTop];
    [attrStr appendAttributedString:attachment];
    label.attribtuedText = attrStr;
    [self.view addSubview:label];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
