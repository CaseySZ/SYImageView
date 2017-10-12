//
//  ViewController.m
//  SYImageView
//
//  Created by ksw on 2017/10/12.
//  Copyright © 2017年 SunYong. All rights reserved.
//

#import "ViewController.h"
#import "SYAsyViewCell.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>{
    
    UITableView *_tableView;
    
    NSMutableArray *cellAry;
    NSMutableArray *iamgeArry;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    
    cellAry = [NSMutableArray new];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(30, 30, [UIScreen mainScreen].bounds.size.width-30,  [UIScreen mainScreen].bounds.size.height-30)];
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    iamgeArry = [[NSMutableArray alloc] init];
    
    [iamgeArry addObject:@"http://img.hb.aicdn.com/0f608994c82c2efce030741f233b29b9ba243db81ddac-RSdX35_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/0f608994c82c2efce030741f233b29b9ba243db81ddac-RSdX35_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/d753396085154f044b905dd5786d32fe85c4c81864c0c-byhUzc_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/d753396085154f044b905dd5786d32fe85c4c81864c0c-byhUzc_fw658"];
    //
    [iamgeArry addObject:@"http://img.hb.aicdn.com/ebf88b4fa5ab5d84d33b0d51a89f5fbe4ded9efe169c6-5zJhaW_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/d01fe4b6ec142f14fb2f13cf80f22a7356e3922110df2-8mnSCV_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/d01fe4b6ec142f14fb2f13cf80f22a7356e3922110df2-8mnSCV_fw658"];
    [iamgeArry addObject:@"http://img.hb.aicdn.com/d01fe4b6ec142f14fb2f13cf80f22a7356e3922110df2-8mnSCV_fw658"];
}


#pragma mark - tableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return iamgeArry.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 200;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    SYAsyViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[SYAsyViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        [cellAry addObject:cell];
    }
    cell.textLabel.text = [@(indexPath.row) description];
    cell.urlStr = iamgeArry[indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPat{
    
    
}

@end
