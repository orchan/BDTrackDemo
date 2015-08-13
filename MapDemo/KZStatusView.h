//
//  KZStatusView.h
//  MapDemo
//
//  Created by ORCHAN on 15/7/13.
//  Copyright (c) 2015年 ORCHAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZTimerLabel.h"
#import <BaiduMapAPI/BMapKit.h>

@interface KZStatusView : UIViewController

// 距离
@property (weak, nonatomic) IBOutlet UILabel *distance;

// 平均速度
@property (weak, nonatomic) IBOutlet UILabel *avgSpeed;

// 目前速度
@property (weak, nonatomic) IBOutlet UILabel *currSpeed;

// 计时器
@property (weak, nonatomic) IBOutlet MZTimerLabel *timerLabel;

// 纬度
@property (weak, nonatomic) IBOutlet UILabel *latituteLabel;

// 经度
@property (weak, nonatomic) IBOutlet UILabel *longtituteLabel;

// 与上一个点的距离
@property (weak, nonatomic) IBOutlet UILabel *distanceWithPreLoc;

// 是否打开百度地理位置服务
@property (weak, nonatomic) IBOutlet UILabel *startLocatonServiceLabel;

// 是否停止百度地理位置复位
@property (weak, nonatomic) IBOutlet UILabel *stopLocatonServiceLabel;

// 是否已经插上开始的旗帜
@property (weak, nonatomic) IBOutlet UILabel *startPointLabel;

// 是否已经插上结束的旗帜
@property (weak, nonatomic) IBOutlet UILabel *stopPointLabel;

// 累计用时
@property (weak, nonatomic) IBOutlet UILabel *sumTime;
@end
