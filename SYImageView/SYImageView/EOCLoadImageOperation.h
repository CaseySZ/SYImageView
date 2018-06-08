//
//  EOCLoadImageOperation.h
//  
//
//  Created by EOC on 2017/5/10.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {

    CutNone = 0, // 正常
    CutHorizLine = 1,//纵向正常，横向截取
    CutVertical = 2,//纵向截取，横向正常
    
}ImageCutStyle;



typedef void(^EOCImageFinishBlock)(UIImage *image);

@interface EOCLoadImageOperation : NSOperation


@property (nonatomic,copy)EOCImageFinishBlock finishBlock;
@property (nonatomic, weak)UIImageView *eocImageV;

@property (nonatomic, assign)ImageCutStyle cutStyle;

@property (nonatomic, strong)NSString *urlStr;


@end
