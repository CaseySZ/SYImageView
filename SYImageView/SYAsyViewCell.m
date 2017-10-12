//
//  EOCAsyViewCell.m
//  EOCFriendLayer
//
//  Created by EOC on 2017/5/5.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import "SYAsyViewCell.h"
#import <objc/runtime.h>
#import "UIImageView+AsyLoad.h"

@implementation SYAsyViewCell


- (void)layoutSubviews{
    
    if (!_imageV) {
        _imageV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:_imageV];
        _textLb = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _textLb.backgroundColor = [UIColor clearColor];
        _textLb.numberOfLines = 0;
        [self addSubview:_textLb];
    }
    _textLb.text = _urlStr;
    [_imageV loadImageWithURL:_urlStr block:^(UIImage *image) {
        
        
    }];
    
}


- (void)removeFromSuperview{
    
    NSLog(@"%s", __func__);
    [super removeFromSuperview];
    
}


- (void)awakeFromNib {
    [super awakeFromNib];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}




- (void)dealloc{
    
    NSLog(@"%s", __func__);
    
}

@end
