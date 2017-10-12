//
//  UIImageView+AsyLoad.h
//  ExamProject
//
//  Created by ksw on 2017/9/30.
//  Copyright © 2017年 SunYong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <stdatomic.h>

@interface UIImageView (AsyLoad)

typedef void(^EOCImageFinishBlock)(UIImage *image);

@property (nonatomic, readonly)NSNumber *monitorValue;
@property (nonatomic, readonly)NSString *urlStr;

- (void)loadImageWithURL:(NSString*)urlStr;
- (void)loadImageWithURL:(NSString*)urlStr block:(EOCImageFinishBlock)imageBlock;



@end
