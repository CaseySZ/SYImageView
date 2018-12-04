//
//  SecondViewController.m
//  SYImageView
//
//  Created by Casey on 04/12/2018.
//  Copyright © 2018 SunYong. All rights reserved.
//

#import "SecondViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+AsyLoad.h"


@interface SecondViewController (){
    
    IBOutlet UIImageView *_imageView;
    
    IBOutlet UIImageView *_syImageView;
}

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [_imageView sd_setImageWithURL:[NSURL URLWithString:@"http://xps-test.oss-cn-shenzhen.aliyuncs.com/article/h6CxQEDcADRWEJwtYEH8bRwwMmMb28zR.png"]];
    
    [_syImageView loadImageWithURL:@"http://xps-test.oss-cn-shenzhen.aliyuncs.com/article/h6CxQEDcADRWEJwtYEH8bRwwMmMb28zR.png"];
    
}


@end
