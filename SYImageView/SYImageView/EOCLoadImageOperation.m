//
//  EOCLoadImageOperation.m
//  
//
//  Created by EOC on 2017/5/10.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import "EOCLoadImageOperation.h"
#import "UIImageView+AsyLoad.h"
#import "UIImage+Bitmap.h"

#import <CommonCrypto/CommonDigest.h>

#define RootDocument ([NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject])
#define SYImageCacheDocument [RootDocument stringByAppendingPathComponent:@"SYImageCacheDocument"]

typedef BOOL (^cancelBlock)(void);

static NSMutableDictionary *__operationTaskInfoDict;
static NSLock *__taskLock;
static NSCache *_imageCahe;

@interface EOCLoadImageOperation (){
}


@end

@implementation EOCLoadImageOperation

@synthesize finished = _finished;

+ (void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __operationTaskInfoDict = [NSMutableDictionary new];
        __taskLock = [NSLock new];
        _imageCahe = [NSCache new];
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
         
        }
    }
}

- (void)main{
    
    typeof(self) __weakSelf = self;
    cancelBlock isCancelBlock = ^BOOL() {
        
        BOOL cancel = NO;
        if (!__weakSelf.eocImageV) {
            cancel = YES;
        }else{
            
            if (__weakSelf.eocImageV.urlStr != __weakSelf.urlStr) {
                cancel = YES;
            }
        }
        if (cancel) {
           
        }
        return cancel;
    };
    
    UIImage *bitmapImage = nil;
    NSData *imageData = [self findUrlDataInLocal];
    if (imageData && imageData.length > 1000) {
        
        bitmapImage = [UIImage imageWithData:imageData];
        if (!isCancelBlock() && bitmapImage){
            [self loadImageInMainThead:bitmapImage];
        }
        
    }else{
        
        if ([__operationTaskInfoDict objectForKey:_urlStr]) {
            
            [__taskLock lock];
            NSMutableArray *sameTaskArray = [__operationTaskInfoDict objectForKey:_urlStr];
            if (self.eocImageV) {
                [sameTaskArray addObject:self.eocImageV];
            }
            [__taskLock unlock];
            
            [self finishStatus];
            return;
            
        }else{
            
            [__taskLock lock];
            [__operationTaskInfoDict setObject:[NSMutableArray array] forKey:_urlStr];
            [__taskLock unlock];
        }
        
        NSData *imageData = [self synLoadImageNet];
        UIImage *netImage = [UIImage imageWithData:imageData];
        
            
        bitmapImage = [netImage eocBitmapStyleImage];
        
        
        [self removeTaskAndExcuteTask:bitmapImage];
        
        [self saveImageData:UIImageJPEGRepresentation(bitmapImage, 1)];
        if (!isCancelBlock() && bitmapImage) {
            [self loadImageInMainThead:bitmapImage];
        }
    }
    
    
    [self finishStatus];
    
}

- (void)removeTaskAndExcuteTask:(UIImage *)bitmapImage{
  
   
    [__taskLock lock];
    NSArray *sameTaskArr = [__operationTaskInfoDict objectForKey:_urlStr];
    [__operationTaskInfoDict removeObjectForKey:_urlStr];
    [__taskLock unlock];
    
    for (int i = 0; i < sameTaskArr.count; i++) {
        
        UIImageView *ecoImageV = sameTaskArr[i];
        if ([ecoImageV isKindOfClass:[UIImageView class]] && [ecoImageV.urlStr isEqualToString:self.urlStr]) {

            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![ecoImageV.image isEqual:bitmapImage]) {
                   ecoImageV.image = bitmapImage;
                }
            });
        }
    }
    
}



- (NSData*)synLoadImageNet{

    NSURL *url = [NSURL URLWithString:_urlStr];
    
    NSURLSession *session = [NSURLSession  sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSData *imageData = nil;
    NSURLSessionTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpRespone = (NSHTTPURLResponse*)response;
        if (error || [httpRespone statusCode] == 404) {
            NSLog(@"网络错误error：%@", error);
        }else{
            imageData = data;
        }
        
        dispatch_semaphore_signal(sem);
    }];
    
    [task resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return imageData;
    
   
}



- (void)loadImageInMainThead:(UIImage*)image{
    
    typeof(self) __weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([__weakSelf.eocImageV.image isEqual:image]) {
            return;
        }
        if (__weakSelf.eocImageV && image) {
            __weakSelf.eocImageV.image = image;
            [__weakSelf.eocImageV setNeedsDisplay];
        }
        if (__weakSelf.finishBlock) {
            __weakSelf.finishBlock(image);
        }
    });
}

- (void)finishStatus{
    
    [self willChangeValueForKey:@"isFinish"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinish"];
    
}

- (NSData*)findUrlDataInLocal{
    
    NSString *fileKey = [self md5FromStr:_urlStr];
    
    if ([_imageCahe objectForKey:fileKey]) {
        return [_imageCahe objectForKey:fileKey];
    }
    
    NSString *filePath = [SYImageCacheDocument stringByAppendingPathComponent:fileKey];
    NSData *imageData = [NSData dataWithContentsOfFile:filePath];
    return imageData;
    
}

- (void)saveImageData:(NSData*)imageData{
    
    NSString *fileKey = [self md5FromStr:_urlStr];
    if (!imageData) {
        imageData = [NSData data];
    }
    [_imageCahe setObject:imageData forKey:fileKey];
    NSString * filePath = [SYImageCacheDocument stringByAppendingPathComponent:fileKey];
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
