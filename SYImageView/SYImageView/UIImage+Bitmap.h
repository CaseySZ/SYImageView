//
//  UIImage+Bitmap.h
//  XPSPlatform
//
//  Created by sy on 2018/4/18.
//  Copyright © 2018年 EOC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Bitmap)

- (UIImage *)eocBitmapStyleImage;
- (BOOL)shouldDecodeImage;


@end


@interface NSData (Bitmap)

- (UIImage*)eocBitmapStyleImage;

@end


