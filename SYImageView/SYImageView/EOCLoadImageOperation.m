//
//  EOCLoadImageOperation.m
//  
//
//  Created by EOC on 2017/5/10.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import "EOCLoadImageOperation.h"
#import "UIImageView+AsyLoad.h"
#import <CommonCrypto/CommonDigest.h>

#define RootDocument ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject])
#define SYImageCacheDocument [RootDocument stringByAppendingPathComponent:@"SYImageCacheDocument"]

typedef BOOL (^cancelBlock)(void);

static NSMutableDictionary *__operationTaskInfoDict;
static NSMutableArray *__eocSameTaskCacheAry;
static NSLock *__taskLock;
@interface EOCLoadImageOperation (){
}


@property (nonatomic, strong)NSData *netData;


@end

@implementation EOCLoadImageOperation

@synthesize finished = _finished;

+ (void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __operationTaskInfoDict = [NSMutableDictionary new];
        __eocSameTaskCacheAry = [NSMutableArray new];
        __taskLock = [NSLock new];
        [self createCacheDocument];
    });

}

+ (void)createCacheDocument{

    BOOL isDocument;
    if ([[NSFileManager defaultManager] fileExistsAtPath:SYImageCacheDocument isDirectory:&isDocument]) {
        if (isDocument) {
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:SYImageCacheDocument error:nil];
    }
    NSError *error = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:SYImageCacheDocument withIntermediateDirectories:YES attributes:nil error:&error];
    if (!created) {
        NSLog(@"创建 缓存文件夹失败:%@", error);
    }else{
        NSURL *url = [NSURL fileURLWithPath:SYImageCacheDocument];
        NSError *error = nil;
        [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];//避免缓存数据 被备份到iclouds
        if (error) {
            NSLog(@"没有成功的设置 ‘应用不能备份的属性’, error = %@", error);
        }
    }
}

- (void)start{
    
    atomic_size_t value = [self.eocImageV.monitorValue intValue];
    typeof(self) __weakSelf = self;
    cancelBlock isCancelBlock = ^BOOL() {
        
        BOOL cancel = NO;
        if (!__weakSelf.eocImageV) {
            cancel = YES;
        }else{
            
            if (__weakSelf.eocImageV.urlStr != self.urlStr && value != [__weakSelf.eocImageV.monitorValue intValue]) {
                cancel = YES;
            }
        }
        if (cancel) {
            NSLog(@"取消了");
        }
        return cancel;
    };
    
    if ([__operationTaskInfoDict objectForKey:_urlStr]) {
       
        [__taskLock lock];
        NSValue *taskValue = [NSValue valueWithNonretainedObject:self.eocImageV];
        [__eocSameTaskCacheAry addObject:taskValue];
        [__taskLock unlock];
        
        [self finishStatus];
        return;
        
    }else{
        
        [__operationTaskInfoDict setObject:@"" forKey:_urlStr];
    }
    
    UIImage *bitmapImage = nil;
    NSData *imageData = [self findUrlDataInLocal];
    if (imageData) {
        bitmapImage = [UIImage imageWithData:imageData];
        if (!isCancelBlock()){
            [self loadImageInMainThead:bitmapImage];
        }
    }else{
        
        [self synLoadImageNet:isCancelBlock bitmapImage:&bitmapImage];
    }
    
    
    [self removeTaskAndExcuteTask:bitmapImage];
    [self finishStatus];
    
}

- (void)removeTaskAndExcuteTask:(UIImage *)bitmapImage{
  
    NSMutableArray *deleteTaskAry = [NSMutableArray new];
    NSMutableArray *excuteTaskAry = [NSMutableArray new];
    [__taskLock lock];
    for (int i = 0; i < __eocSameTaskCacheAry.count; i++) {
        
        NSValue *taskV = __eocSameTaskCacheAry[i];
        UIImageView *ecoImageV = taskV.nonretainedObjectValue;
        if (!ecoImageV) {
            [deleteTaskAry addObject:taskV];
        }else{
            
            if ([ecoImageV.urlStr isEqualToString:self.urlStr]) {
                [excuteTaskAry addObject:taskV];
            }
            
        }
        
    }
    
    for (int i = 0; i < deleteTaskAry.count; i++) {
        [__eocSameTaskCacheAry removeObject:deleteTaskAry[i]];
    }
    
    for (int i = 0; i < excuteTaskAry.count; i++) {
        [__eocSameTaskCacheAry removeObject:excuteTaskAry[i]];
    }
    [__taskLock unlock];
    
    for (int i = 0; i < excuteTaskAry.count; i++) {
        
        NSValue *taskV = excuteTaskAry[i];
        UIImageView *ecoImageV = taskV.nonretainedObjectValue;
        if (ecoImageV && ecoImageV != self.eocImageV) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ecoImageV.layer.contents = (__bridge id)bitmapImage.CGImage;// bitmap
            });
        }
    }
    
    [deleteTaskAry removeAllObjects];
    [excuteTaskAry removeAllObjects];
    
}



- (void)synLoadImageNet:(cancelBlock)isCancelBlock bitmapImage:(UIImage**)bitmapImage{

    NSURL *url = [NSURL URLWithString:_urlStr];
    
    NSURLSession *session = [NSURLSession  sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    typeof(self) __weakSelf = self;
    NSURLSessionTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse*)response;
        if (error || [httpRespone statusCode] == 404) {
            NSLog(@"网络错误error：%@", error);
        }else{
            __weakSelf.netData = data;
        }
        
        dispatch_semaphore_signal(sem);
    }];
    
    [task resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    if (self.netData) {
        
        *bitmapImage = [self eocBitmapStyleImageFromImageData:self.netData];
        [self saveImageData:UIImageJPEGRepresentation(*bitmapImage, 1)];
        
    }
    if (!isCancelBlock()) {
        [self loadImageInMainThead:*bitmapImage];
    }
}



- (void)loadImageInMainThead:(UIImage*)image{
    
    typeof(self) __weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
       
        if (__weakSelf.eocImageV) {
            __weakSelf.eocImageV.image = image;
            //__weakSelf.eocImageV.layer.contents = (__bridge id)image.CGImage;
        }
    });
}

- (void)finishStatus{
    
    [self willChangeValueForKey:@"isFinish"];
    _finished = YES;
    [__operationTaskInfoDict removeObjectForKey:_urlStr];
    [self didChangeValueForKey:@"isFinish"];
    
}


- (UIImage *)eocBitmapStyleImageFromImageData:(NSData*)imageData{
    
    UIImage *netImage = [UIImage imageWithData:imageData];
    CGImageRef imageRef = netImage.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
    bool unsupportedColorSpace = (imageColorSpaceModel == 0 || imageColorSpaceModel == -1 || imageColorSpaceModel == kCGColorSpaceModelCMYK || imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace)
        colorspaceRef = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef contextRef =  CGBitmapContextCreate(NULL, width, height,
                                                     CGImageGetBitsPerComponent(imageRef),
                                                     CGImageGetBytesPerRow(imageRef),
                                                     colorspaceRef,
                                                     CGImageGetBitmapInfo(imageRef));
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef backImageRef = CGBitmapContextCreateImage(contextRef);
    
    UIImage *bitmapImage = [UIImage imageWithCGImage:backImageRef scale:[UIScreen mainScreen].scale orientation:netImage.imageOrientation];
    
    CFRelease(backImageRef);
    UIGraphicsEndImageContext();
    
    return bitmapImage;
    
   
    
}



- (NSData*)findUrlDataInLocal{
    
    NSString *filePath = [SYImageCacheDocument stringByAppendingPathComponent:[self md5FromStr:_urlStr]];
    return [NSData dataWithContentsOfFile:filePath];
    
}

- (void)saveImageData:(NSData*)imageData{
    
    NSString * filePath = [SYImageCacheDocument stringByAppendingPathComponent:[self md5FromStr:_urlStr]];
    [imageData writeToFile:filePath atomically:YES];
    
}

- (NSString*)md5FromStr:(NSString*)targetStr{
    
    if(targetStr.length == 0){
        return nil;
    }
    const char *original_str = [targetStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (unsigned int)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}

@end
