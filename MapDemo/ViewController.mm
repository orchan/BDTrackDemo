//
//  ViewController.m
//  MapDemo
//
//  Created by ORCHAN on 15/7/9.
//  Copyright (c) 2015年 ORCHAN. All rights reserved.
//

#import "ViewController.h"
#import <BaiduMapAPI/BMapKit.h>
#import <BaiduMapAPI/BMKMapView.h>
#import "KZStatusView.h"
#import "MZTimerLabel.h"

typedef enum : NSUInteger {
    TrailStart,
    TrailEnd
} Trail;

@interface ViewController () <BMKMapViewDelegate, BMKLocationServiceDelegate>

/** 百度定位地图服务 */
@property (nonatomic, strong) BMKLocationService *bmkLocationService;

/** 百度地图View */
@property (nonatomic,strong) BMKMapView *mapView;

/** 半透明状态显示View */
@property (nonatomic,strong) KZStatusView *statusView;

/** 记录上一次的位置 */
@property (nonatomic, strong) CLLocation *preLocation;

/** 位置数组 */
@property (nonatomic, strong) NSMutableArray *locationArrayM;

/** 轨迹线 */
@property (nonatomic, strong) BMKPolyline *polyLine;

/** 轨迹记录状态 */
@property (nonatomic, assign) Trail trail;

/** 起点大头针 */
@property (nonatomic, strong) BMKPointAnnotation *startPoint;

/** 终点大头针 */
@property (nonatomic, strong) BMKPointAnnotation *endPoint;

/** 累计步行时间 */
@property (nonatomic,assign) NSTimeInterval sumTime;

/** 累计步行距离 */
@property (nonatomic,assign) CGFloat sumDistance;

@end

@implementation ViewController

#pragma mark - Lifecycle Method

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化百度位置服务
    [self initBMLocationService];
    
    // 初始化导航栏的一些属性
    [self setupNavigationProperty];
    
    // 初始化 状态信息 控制器
    self.statusView = [[KZStatusView alloc]init];
    
    // 初始化地图窗口
    self.mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
    
    // 设置MapView的一些属性
    [self setMapViewProperty];
    
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.statusView.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.mapView viewWillAppear];
    self.mapView.delegate = self;
    self.bmkLocationService.delegate = self;
    
    self.navigationController.navigationBar.barStyle    = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.mapView viewWillDisappear];
    self.mapView.delegate = nil;
    self.bmkLocationService.delegate = nil;
}

- (void)viewWillLayoutSubviews
{
    self.statusView.view.frame = CGRectMake(20, DeviceHeight - 270, 338, 261);
}

#pragma mark - Customize Method

/**
 *  设置导航栏的一些属性
 */
- (void)setupNavigationProperty
{
    // 导航栏中部标题
    self.title = @"TrackingRecord";
    
    // 导航栏左侧按钮
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Start Record"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(startTrack)];
    // 导航栏右侧按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Stop Record"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(stopTrack)];
}

/**
 *  初始化百度位置服务
 */
- (void)initBMLocationService
{
    // 初始化位置百度位置服务
    self.bmkLocationService = [[BMKLocationService alloc] init];
    
    //设置更新位置频率(单位：米;必须要在开始定位之前设置)
    [BMKLocationService setLocationDistanceFilter:5];
    [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBest];
}

/**
 *  设置 百度MapView的一些属性
 */
- (void)setMapViewProperty
{
    // 显示定位图层
    self.mapView.showsUserLocation = YES;
    
    // 设置定位模式
    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    
    // 允许旋转地图
    self.mapView.rotateEnabled = YES;
    
    // 显示比例尺
    //    self.bmkMapView.showMapScaleBar = YES;
    //    self.bmkMapView.mapScaleBarPosition = CGPointMake(self.view.frame.size.width - 50, self.view.frame.size.height - 50);
    
    // 定位图层自定义样式参数
    BMKLocationViewDisplayParam *displayParam = [[BMKLocationViewDisplayParam alloc]init];
    displayParam.isRotateAngleValid = NO;//跟随态旋转角度是否生效
    displayParam.isAccuracyCircleShow = NO;//精度圈是否显示
    displayParam.locationViewOffsetX = 0;//定位偏移量(经度)
    displayParam.locationViewOffsetY = 0;//定位偏移量（纬度）
    displayParam.locationViewImgName = @"walk";
    [self.mapView updateLocationViewWithParam:displayParam];
}

#pragma mark - "IBAction" Method

/**
 *  开启百度地图定位服务
 */
- (void)startTrack
{
    // 1.清理上次遗留的轨迹路线以及状态的残留显示
    [self clean];
    
    // 2.打开定位服务
    [self.bmkLocationService startUserLocationService];
    
    // 3.更新状态栏的“是否打开地理位置服务”的 Label
    self.statusView.startLocatonServiceLabel.text = @"YES";
    self.statusView.stopLocatonServiceLabel.text = @"NO";
    
    // 4.设置当前地图的显示范围，直接显示到用户位置
    BMKCoordinateRegion adjustRegion = [self.mapView regionThatFits:BMKCoordinateRegionMake(self.bmkLocationService.userLocation.location.coordinate, BMKCoordinateSpanMake(0.02f,0.02f))];
    [self.mapView setRegion:adjustRegion animated:YES];
    
    // 5.如果计时器在计时则复位
    if ([self.statusView.timerLabel counting] || self.statusView.timerLabel.text != nil) {
        [self.statusView.timerLabel reset];
    }
    
    // 6.开始计时
    [self.statusView.timerLabel start];
    
    // 7.设置轨迹记录状态为：开始
    self.trail = TrailStart;
}

/**
 *  停止百度地图定位服务
 */
- (void)stopTrack
{
    // 1.停止计时器
    [self.statusView.timerLabel pause];
    NSLog(@"累计计时为：%@",self.statusView.timerLabel.text);
    
    // 2.更新状态栏的“是否打开地理位置服务”的 Label
    self.statusView.startLocatonServiceLabel.text = @"NO";
    self.statusView.stopLocatonServiceLabel.text = @"YES";
    
    // 3.设置轨迹记录状态为：结束
    self.trail = TrailEnd;
    
    // 4.关闭定位服务
    [self.bmkLocationService stopUserLocationService];
    
    // 5.添加终点旗帜
    if (self.startPoint) {
        self.endPoint = [self creatPointWithLocaiton:self.preLocation title:@"终点"];
    }
}

#pragma mark - BMKLocationServiceDelegate
/**
 *  定位失败会调用该方法
 *
 *  @param error 错误信息
 */
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"did failed locate,error is %@",[error localizedDescription]);
    UIAlertView *gpsWeaknessWarning = [[UIAlertView alloc]initWithTitle:@"Positioning Failed" message:@"Please allow to use your Location via Setting->Privacy->Location" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [gpsWeaknessWarning show];
}

/**
 *  用户位置更新后，会调用此函数
 *  @param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    // 1. 动态更新我的位置数据
    [self.mapView updateLocationData:userLocation];
    NSLog(@"La:%f, Lo:%f", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    
    // 2. 更新状态栏的经纬度 Label
    self.statusView.latituteLabel.text = [NSString stringWithFormat:@"%.4f",userLocation.location.coordinate.latitude];
    self.statusView.longtituteLabel.text = [NSString stringWithFormat:@"%.4f",userLocation.location.coordinate.longitude];
    self.statusView.avgSpeed.text = [NSString stringWithFormat:@"%.2f",userLocation.location.speed];
    
    // 3. 如果精准度不在100米范围内
    if (userLocation.location.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters) {
        NSLog(@"userLocation.location.horizontalAccuracy is %f",userLocation.location.horizontalAccuracy);
        UIAlertView *gpsSignal = [[UIAlertView alloc]initWithTitle:@"GPS Signal" message:@"Hey,GPS Signal is terrible,please move your body..." delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil, nil];
        [gpsSignal show];
        return;
    }//else if (TrailStart == self.trail) { // 开始记录轨迹
        [self startTrailRouteWithUserLocation:userLocation];
    //}
}

/**
 *  用户方向更新后，会调用此函数
 *  @param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    // 动态更新我的位置数据
    [self.mapView updateLocationData:userLocation];
}


#pragma mark - Selector for didUpdateBMKUserLocation:
/**
 *  开始记录轨迹
 *
 *  @param userLocation 实时更新的位置信息
 */
- (void)startTrailRouteWithUserLocation:(BMKUserLocation *)userLocation
{
    if (self.preLocation) {
        // 计算本次定位数据与上次定位数据之间的时间差
        NSTimeInterval dtime = [userLocation.location.timestamp timeIntervalSinceDate:self.preLocation.timestamp];
        
        // 累计步行时间
        self.sumTime += dtime;
        self.statusView.sumTime.text = [NSString stringWithFormat:@"%.3f",self.sumTime];
        
        // 计算本次定位数据与上次定位数据之间的距离
        CGFloat distance = [userLocation.location distanceFromLocation:self.preLocation];
        self.statusView.distanceWithPreLoc.text = [NSString stringWithFormat:@"%.3f",distance];
        NSLog(@"与上一位置点的距离为:%f",distance);
        
        // (5米门限值，存储数组划线) 如果距离少于 5 米，则忽略本次数据直接返回该方法
        if (distance < 5) {
            NSLog(@"与前一更新点距离小于5m，直接返回该方法");
            return;
        }
        
        // 累加步行距离
        self.sumDistance += distance;
        self.statusView.distance.text = [NSString stringWithFormat:@"%.3f",self.sumDistance / 1000.0];
        NSLog(@"步行总距离为:%f",self.sumDistance);
        
        // 计算移动速度
        CGFloat speed = distance / dtime;
        self.statusView.currSpeed.text = [NSString stringWithFormat:@"%.3f",speed];
        
        // 计算平均速度
        CGFloat avgSpeed  =self.sumDistance / self.sumTime;
        self.statusView.avgSpeed.text = [NSString stringWithFormat:@"%.3f",avgSpeed];
    }
    
    // 2. 将符合的位置点存储到数组中
    [self.locationArrayM addObject:userLocation.location];
    self.preLocation = userLocation.location;
    
    // 3. 绘图
    [self drawWalkPolyline];
    
}

/**
 *  绘制步行轨迹路线
 */
- (void)drawWalkPolyline
{
    //轨迹点
    NSUInteger count = self.locationArrayM.count;
    
    // 手动分配存储空间，结构体：地理坐标点，用直角地理坐标表示 X：横坐标 Y：纵坐标
    BMKMapPoint *tempPoints = new BMKMapPoint[count];
    
    [self.locationArrayM enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        BMKMapPoint locationPoint = BMKMapPointForCoordinate(location.coordinate);
        tempPoints[idx] = locationPoint;
        NSLog(@"idx = %ld,tempPoints X = %f Y = %f",idx,tempPoints[idx].x,tempPoints[idx].y);
        
        // 放置起点旗帜
        if (0 == idx && TrailStart == self.trail && self.startPoint == nil) {
            self.startPoint = [self creatPointWithLocaiton:location title:@"起点"];
        }
    }];
    
    //移除原有的绘图
    if (self.polyLine) {
        [self.mapView removeOverlay:self.polyLine];
    }
    
    // 通过points构建BMKPolyline
    self.polyLine = [BMKPolyline polylineWithPoints:tempPoints count:count];
    
    //添加路线,绘图
    if (self.polyLine) {
        [self.mapView addOverlay:self.polyLine];
    }
    
    // 清空 tempPoints 内存
    delete []tempPoints;
    
    [self mapViewFitPolyLine:self.polyLine];
}

/**
 *  添加一个大头针
 *
 *  @param location
 */
- (BMKPointAnnotation *)creatPointWithLocaiton:(CLLocation *)location title:(NSString *)title;
{
    BMKPointAnnotation *point = [[BMKPointAnnotation alloc] init];
    point.coordinate = location.coordinate;
    point.title = title;
    [self.mapView addAnnotation:point];
    
    return point;
}

/**
 *  清空数组以及地图上的轨迹
 */
- (void)clean
{
    // 清空状态栏信息
    self.statusView.distance.text = nil;
    self.statusView.avgSpeed.text = nil;
    self.statusView.currSpeed.text = nil;
    self.statusView.sumTime.text = nil;
    self.statusView.latituteLabel.text = nil;
    self.statusView.longtituteLabel.text = nil;
    self.statusView.distanceWithPreLoc.text = nil;
    self.statusView.startLocatonServiceLabel.text = @"NO";
    self.statusView.stopLocatonServiceLabel.text = @"YES";
    self.statusView.startPointLabel.text = @"NO";
    self.statusView.stopPointLabel.text = @"NO";
    
    //清空数组
    [self.locationArrayM removeAllObjects];
    
    //清屏，移除标注点
    if (self.startPoint) {
        [self.mapView removeAnnotation:self.startPoint];
        self.startPoint = nil;
    }
    if (self.endPoint) {
        [self.mapView removeAnnotation:self.endPoint];
        self.endPoint = nil;
    }
    if (self.polyLine) {
        [self.mapView removeOverlay:self.polyLine];
        self.polyLine = nil;
    }
}

/**
 *  根据polyline设置地图范围
 *
 *  @param polyLine
 */
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    [self.mapView setVisibleMapRect:rect];
    self.mapView.zoomLevel = self.mapView.zoomLevel - 0.3;
}


#pragma mark - BMKMapViewDelegate

/**
 *  根据overlay生成对应的View
 *  @param mapView 地图View
 *  @param overlay 指定的overlay
 *  @return 生成的覆盖物View
 */
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor clearColor] colorWithAlphaComponent:0.7];
        polylineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
        polylineView.lineWidth = 10.0;
        return polylineView;
    }
    return nil;
}

/**
 *  只有在添加大头针的时候会调用，直接在viewDidload中不会调用
 *  根据anntation生成对应的View
 *  @param mapView 地图View
 *  @param annotation 指定的标注
 *  @return 生成的标注View
 */
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        if(self.startPoint){ // 有起点旗帜代表应该放置终点旗帜（程序一个循环只放两张旗帜：起点与终点）
            annotationView.pinColor = BMKPinAnnotationColorGreen; // 替换资源包内的图片
            self.statusView.stopPointLabel.text = @"YES";
        }else { // 没有起点旗帜，应放置起点旗帜
            annotationView.pinColor = BMKPinAnnotationColorPurple;
            self.statusView.startPointLabel.text = @"YES";
        }
        
        // 从天上掉下效果
        annotationView.animatesDrop = YES;
        
        // 不可拖拽
        annotationView.draggable = NO;
        
        return annotationView;
    }
    return nil;
}


#pragma mark - lazyLoad

- (NSMutableArray *)locationArrayM
{
    if (_locationArrayM == nil) {
        _locationArrayM = [NSMutableArray array];
    }
    
    return _locationArrayM;
}

@end
