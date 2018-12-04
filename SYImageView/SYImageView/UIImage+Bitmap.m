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
    CGContextRef contextRef =  CGBitmapContextCreate(NULL, width, height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast|kCGImageAlphaPremultipliedLast);
    
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

- (BOOL)shouldDecodeImage {
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (self == nil) {
        return NO;
    }
    
    // do not decode animated images
    if (self.images != nil) {
        return NO;
    }
    
    CGImageRef imageRef = self.CGImage;
    
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                     alpha == kCGImageAlphaLast ||
                     alpha == kCGImageAlphaPremultipliedFirst ||
                     alpha == kCGImageAlphaPremultipliedLast);
    // do not decode images with alpha
    if (anyAlpha) {
        return NO;
    }
    
    return YES;
}


@end



@implementation NSData (Bitmap)

- (UIImage*)eocBitmapStyleImage{
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (imageSource){
        
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        if (partialImageRef) {
            
            size_t width = CGImageGetWidth(partialImageRef);
            size_t height = CGImageGetHeight(partialImageRef);
            const size_t partialHeight = CGImageGetHeight(partialImageRef);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
            CGColorSpaceRelease(colorSpace);
            if (bmContext) {
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                CGImageRelease(partialImageRef);
                partialImageRef = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
            }
            else {
                CGImageRelease(partialImageRef);
                partialImageRef = nil;
            }
        }
        
        if (partialImageRef) {
            
            
            UIImage *image = [UIImage imageWithCGImage:partialImageRef];
            CGImageRelease(partialImageRef);
            return image;
        }
    }
    
    
    return nil;
    
    
}


- (UIImageOrientation)orientationFromPropertyValue:(CGImageSourceRef)imageSource{
    
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    if (properties) {
        NSInteger orientationValue = -1;
        
        CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
        if (val) {
            CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
        }
        CFRelease(properties);
        
        
        
        UIImageOrientation orientation = [NSData orientationValue:(orientationValue == -1 ? 1 : orientationValue)];
        return orientation;
    }
    return UIImageOrientationUp;
}


+ (UIImageOrientation)orientationValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

@end




