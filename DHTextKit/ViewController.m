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
    UIFont *font = [UIFont boldSystemFontOfSize:30];
    UIColor *color = [UIColor redColor];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(5, 5);
    shadow.shadowBlurRadius = 10;
    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : color,
                                 NSShadowAttributeName : shadow};
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"Any" attributes:attributes];
    NSAttributedString *attachment = [NSAttributedString dh_attachmentStringWithContent:[UIImage imageNamed:@"Delete.png"]
                                                                            contentMode:UIViewContentModeScaleToFill
                                                                         attachmentSize:CGSizeMake(15, 30)
                                                                            alignToFont:font
                                                                      verticalAlignment:DHTextVerticalAlignmentBottom];
    NSAttributedString *tail = [[NSAttributedString alloc] initWithString:@"thing you want to sayladjlasdlasd" attributes:attributes];
    [attrStr appendAttributedString:tail];
    [attrStr appendAttributedString:attachment];
    label.attribtuedText = attrStr;
    [label sizeToFit];
    [self.view addSubview:label];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
