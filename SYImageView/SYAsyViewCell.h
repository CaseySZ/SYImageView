//
//  EOCAsyViewCell.h
//  EOCFriendLayer
//
//  Created by EOC on 2017/5/5.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SYAsyViewCell : UITableViewCell{
    
    UIImageView *_imageV;
    UILabel *_textLb;
}

@property (nonatomic, strong)NSString *urlStr;

@end
