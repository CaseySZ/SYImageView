//
//  CaseyBlurView.m
//  IOS_B01
//
//  Created by Casey on 13/02/2019.
//  Copyright © 2019 Casey. All rights reserved.
//

#import "CaseyBlurView.h"
#import <Accelerate/Accelerate.h>

@interface CaseyBlurView (){
    
    UIImageView *_imageView;
    UIVisualEffectView *_efferView;
}



@end



@implementation CaseyBlurView



- (instancetype)initWithFrame:(CGRect)frame {
    
    
    self = [super initWithFrame:frame];
    if (self) {
        
        
       
        _efferView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _efferView.frame = UIScreen.mainScreen.bounds;
        _efferView.alpha = 1;
        _efferView.hidden = YES;
        [self addSubview:_efferView];
        
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
        
        
        
    }
    
    return self;
    
}


- (void)layoutSubviews {
    
    [super layoutSubviews];
    _efferView.frame = self.bounds;
    _imageView.frame = self.bounds;
}


- (void)loadBlurImage:(UIImage*)blurImage {
    
    if (blurImage != nil) {
        
        _imageView.image = blurImage;
        [_efferView removeFromSuperview];
        
    }else {
        _efferView.hidden = NO;
    }
}

- (void)renderBlurView:(UIView* _Nullable)targertView maskColor:(UIColor* _Nullable)maskColor{
    
    if (targertView == nil) {
        UIViewController *rootViewCtr =  UIApplication.sharedApplication.delegate.window.rootViewController;
        targertView = rootViewCtr.view;
    }
    
    CALayer *targetLayer = targertView.layer;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *viewImage = [self screenshotWithView:targetLayer];
        UIImage *blurImage = [self applyBlurWithImage:viewImage maskColor:maskColor];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self loadBlurImage:blurImage];

        });
        
    });
    
}

- (UIImage *)screenshotWithView:(CALayer*)targetLayer
{
    
    CGFloat scale =  1;
    CGFloat width = targetLayer.frame.size.width*scale;
    CGFloat height = targetLayer.frame.size.height*scale;
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    [targetLayer renderInContext:context];
    
    CGImageRef imageRef =  CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    
    if (imageRef) {
        CFRelease(imageRef);
    }
    if (context) {
        CFRelease(context);
    }
    
    return  image;
}


- (UIImage *)applyBlurWithImage:(UIImage *)targetImage maskColor:(UIColor* _Nullable)maskColor
{
    // Check pre-conditions.
    
    CGFloat blurRadius = 10;
    CGFloat saturationDeltaFactor = 1;
    
    if (targetImage.size.width < 1 || targetImage.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", targetImage.size.width, targetImage.size.height, targetImage);
        return nil;
    }
    if (!targetImage.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", targetImage);
        return nil;
    }
    if (targetImage && !targetImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", targetImage);
        return nil;
    }
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    
    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat width = targetImage.size.width*scale;
    CGFloat height = targetImage.size.height*scale;
    CGRect imageRect = CGRectMake(0, 0, width, height);
    UIImage *effectImage = targetImage;
    if (hasBlur || hasSaturationChange) {
        
        
        CGContextRef effectInContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(effectInContext, imageRect, targetImage.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        
        CGContextRef effectOutContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
        
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        
        if (hasBlur) {
            
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImage_Error error = vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            error = vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            error = vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        
        
        CGImageRef imageRef =  CGBitmapContextCreateImage(effectOutContext);
        effectImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        
        if (imageRef) {
            CFRelease(imageRef);
        }
        if (effectInContext) {
            CFRelease(effectInContext);
        }
        if (effectOutContext) {
            CFRelease(effectOutContext);
        }
    }
    
    
    // Set up output context.
    CGContextRef outputContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, targetImage.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (maskColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, maskColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    
    CGImageRef imageRef =  CGBitmapContextCreateImage(outputContext);
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    
    if (imageRef) {
        CFRelease(imageRef);
    }
    if (outputContext) {
        CFRelease(outputContext);
    }
    
    return outputImage;
    
}

@end
