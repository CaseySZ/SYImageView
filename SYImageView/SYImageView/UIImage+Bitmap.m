//
//  UIImage+Bitmap.m
//  XPSPlatform
//
//  Created by sy on 2018/4/18.
//  Copyright © 2018年 EOC. All rights reserved.
//

#import "UIImage+Bitmap.h"

@implementation UIImage (Bitmap)

- (UIImage *)eocBitmapStyleImage{
    
    CGImageRef imageRef = self.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
    BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                  imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                  imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                  imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace) {
        colorspaceRef = CGColorSpaceCreateDeviceRGB();
    }
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    //CGBitmapInfo bitmapInfo =  CGImageGetBitmapInfo(imageRef)
    CGContextRef contextRef =  CGBitmapContextCreate(NULL, width, height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef backImageRef = CGBitmapContextCreateImage(contextRef);
    
    UIImage *bitmapImage = [UIImage imageWithCGImage:backImageRef scale:[UIScreen mainScreen].scale orientation:self.imageOrientation];
    if (bitmapImage == nil) {
        NSLog(@"图片解码失败");
    }
    if (contextRef) {
        CGContextRelease(contextRef);
    }
    if (backImageRef) {
        CFRelease(backImageRef);
    }else{
        
        NSLog(@"image data");
    }
    
    return bitmapImage;
}

//// 暂未实现   纵向不变，切除多余的横向区域
- (UIImage *)eocBitmapInSizeAndCutHorizLine:(CGSize)tagertSize{
    
    CGImageRef imageRef = self.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
    BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                  imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                  imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                  imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace) {
        colorspaceRef = CGColorSpaceCreateDeviceRGB();
    }
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef contextRef =  CGBitmapContextCreate(NULL, width, height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
    
    // 截取区域
    // 注意scaleCount 大于1的情况
    CGFloat scaleCount = tagertSize.width/tagertSize.height;
    CGFloat realWidth = scaleCount*height;
    
    CGRect clipRect = CGRectMake((width-realWidth)/2, 0, realWidth, height);
    CGContextAddRect(contextRef, clipRect);
    CGContextClip(contextRef);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);

    CGImageRef backImageRef = CGBitmapContextCreateImage(contextRef);
    
    UIImage *bitmapImage = [UIImage imageWithCGImage:backImageRef scale:[UIScreen mainScreen].scale orientation:self.imageOrientation];
    
    
    
    
    if (contextRef) {
        CGContextRelease(contextRef);
    }
    if (backImageRef) {
        CFRelease(backImageRef);
    }else{
        // http://xps-test.oss-cn-shenzhen.aliyuncs.com/article/h6CxQEDcADRWEJwtYEH8bRwwMmMb28zR.png
        NSLog(@"image data error");
    }
    
    
    
    return bitmapImage;
}


@end
