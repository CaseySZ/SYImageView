//
//  EOCLoadImageOperation.h
//  
//
//  Created by EOC on 2017/5/10.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^EOCImageFinishBlock)(UIImage *image);

@interface EOCLoadImageOperation : NSOperation


@property (nonatomic,copy)EOCImageFinishBlock finishBlock;
@property (nonatomic, weak)UIImageView *eocImageV;

@property (nonatomic, strong)NSString *urlStr;

@end
