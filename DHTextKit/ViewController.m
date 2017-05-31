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
#import "DHTextShadow.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    DHLabel *label = [[DHLabel alloc] initWithFrame:CGRectMake(100, 100, 200, 100)];
    label.maximumNumberOfRows = 2;
    label.truncationType = DHTextTruncationTypeEnd;
    label.truncationToken = [[NSAttributedString alloc] initWithString:@"YES"];
//    label.lineBreakMode = NSLineBreakByCharWrapping;
    UIFont *font = [UIFont boldSystemFontOfSize:16];
    UIColor *color = [UIColor whiteColor];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    shadow.shadowOffset = CGSizeMake(1, 3);
    shadow.shadowBlurRadius = 3;
    DHTextShadow *textShadow = [DHTextShadow shadowWithNSShadow:shadow];
    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : color,
                                 DHTextInnerShadowAttributeName : textShadow};
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"Any" attributes:attributes];
    NSAttributedString *attachment = [NSAttributedString dh_attachmentStringWithContent:[UIImage imageNamed:@"Delete.png"]
                                                                            contentMode:UIViewContentModeScaleToFill
                                                                         attachmentSize:CGSizeMake(15, 30)
                                                                            alignToFont:font
                                                                      verticalAlignment:DHTextVerticalAlignmentBottom];
    NSAttributedString *tail = [[NSAttributedString alloc] initWithString:@"thing you want to sayladjlasdlasd" attributes:attributes];
    [attrStr appendAttributedString:tail];
    [attrStr appendAttributedString:attachment];
//    [attrStr setStrokeColor:[UIColor blueColor]];
//    [attrStr setStrokeWidth:@(5)];
    [attrStr setLineBreakMode:NSLineBreakByCharWrapping];
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
