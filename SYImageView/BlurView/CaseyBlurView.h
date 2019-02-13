//
//  CaseyBlurView.h
//  IOS_B01
//
//  Created by Casey on 13/02/2019.
//  Copyright © 2019 Casey. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 问题： scale 未处理。 
 
 关键vImageBoxConvolve_ARGB8888 对像素的处理
 
 自制实现方案：模糊效果：尝试修改像素值来做简单处理，黑白像素不做处理（基准以RGB相差10个像素左右偏差）， 虚化效果可以利用毛玻璃透明0.5。
 
 */


@interface CaseyBlurView : UIView




/**
 
高斯模糊
 @param targertView 当前模糊的view； 传nil 默认是keywindow根控制器的view
 @param maskColor 颜色遮罩，模糊之后，再添加一层颜色，无默认值
 */
- (void)renderBlurView:(UIView* _Nullable)targertView maskColor:(UIColor* _Nullable)maskColor;



@end


