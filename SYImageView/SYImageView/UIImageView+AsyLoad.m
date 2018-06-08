//
//  UIImageView+AsyLoad.m
//  ExamProject
//
//  Created by ksw on 2017/9/30.
//  Copyright © 2017年 SunYong. All rights reserved.
//

#import "UIImageView+AsyLoad.h"
#import "EOCLoadImageOperation.h"
#import <objc/runtime.h>

@implementation UIImageView (AsyLoad)

static NSOperationQueue *_eocImageOpQueue;
+ (void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _eocImageOpQueue = [NSOperationQueue new];
        _eocImageOpQueue.maxConcurrentOperationCount = 5;
    });
}

static char __syMonitorValue;
- (void)setMonitorValue:(NSNumber*)monitorValue{
    
    objc_setAssociatedObject(self, &__syMonitorValue, monitorValue, OBJC_ASSOCIATION_ASSIGN);
}

- (NSNumber*)monitorValue{

   return objc_getAssociatedObject(self, &__syMonitorValue);
    
}

static char __syUrlImage;
- (void)setUrlStr:(NSString *)urlStr{
    
     objc_setAssociatedObject(self, &__syUrlImage, urlStr, OBJC_ASSOCIATION_RETAIN);
}

- (NSString*)urlStr{
    
    return objc_getAssociatedObject(self, &__syUrlImage);
    
}

- (void)loadImageWithURL:(NSString*)urlStr{
    
    [self loadImageWithURL:urlStr block:nil];
}

- (void)loadImageNormalScaleHeightWithURL:(NSString *)urlStr{
    
    [self loadImageWithURL:urlStr cutOut:CutHorizLine block:nil];
    
}


- (void)loadImageWithURL:(NSString*)urlStr defaultImage:(UIImage*)image{
    
    if (!self.image) {
        self.image = image;
    }
    [self loadImageWithURL:urlStr block:nil];
}

- (void)loadImageWithURL:(NSString*)urlStr block:(EOCImageFinishBlock)imageBlock{
    
    [self loadImageWithURL:urlStr cutOut:CutNone block:imageBlock];
}


- (void)loadImageWithURL:(NSString*)urlStr cutOut:(ImageCutStyle)cutStyle block:(EOCImageFinishBlock)imageBlock{
    
    if (!urlStr || urlStr.length < 10) {
        return;
    }
    self.urlStr = urlStr;
    
    atomic_size_t monitorV = self.monitorValue.intValue;
    atomic_fetch_add(&monitorV, 1);
    self.monitorValue = [NSNumber numberWithInt:monitorV];
    
    // 这里 monitorV可以直接赋值
    EOCLoadImageOperation *loadImageOp = [[EOCLoadImageOperation alloc] init];
    loadImageOp.eocImageV = self;
    loadImageOp.urlStr = urlStr;
    loadImageOp.finishBlock = imageBlock;
    loadImageOp.cutStyle = cutStyle;
    
    [_eocImageOpQueue addOperation:loadImageOp];
}


@end
