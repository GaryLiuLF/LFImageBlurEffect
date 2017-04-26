//
//  ViewController.m
//  ImageBlurEffect
//
//  Created by gary.liu on 17/4/24.
//  Copyright © 2017年 刘林飞. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <FXBlurView.h>
#import <GPUImage.h>
#import "UIImage+ImageEffects.h"

@interface ViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIImageView *imageView;

@property (nonatomic, copy) NSArray *items;

@end

@implementation ViewController

- (NSArray *)items {
    if (!_items) {
        _items = @[@"CoreImage(狂吃内存)", @"Effect(系统自带)", @"UIImage+Effects", @"GPUImage(狂吃内存)", @"FXBlurView"];
    }
    return _items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUI];
}

- (void)setupUI {
    self.title = @"图片各种滤镜";
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    CGFloat rHeight = 50;
    UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 250) style:UITableViewStylePlain];
    NSLog(@"%f, %f", self.items.count * rHeight, CGRectGetHeight(tableView.frame));
    tableView.bounces = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = rHeight;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    CGFloat iHeight = self.view.frame.size.height - 64 - self.items.count * rHeight - 20;
    CGFloat iWidth = iHeight * 0.56;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(tableView.frame) + 10, iWidth, iHeight)];
    imageView.center = CGPointMake(self.view.center.x, imageView.center.y);
    imageView.image = [UIImage imageNamed:@"image"];
    [self.view addSubview:imageView];
    self.imageView = imageView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

#pragma mark - UItableVIewDelegate
static NSString *cellId = @"cellId";
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self useCoreImage];
            break;
        case 1:
            [self useSystemEffect];
            break;
        case 2:
            [self useImageEffect];
            break;
        case 3:
            [self useGPUImage];
            break;
        case 4:
            [self useFXBlurView];
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.imageView.image = [UIImage imageNamed:@"image"];
}


/**
 第一种：CoreImage使用
 优点：模糊效果较好，模糊程度的可调范围很大，可以根据实际的需求随意调试。
 缺点：耗时，过一段时间才会显示，非常消耗内存，不建议使用
 需要导入 <CoreImage/CoreImage.h>
 */
- (void)useCoreImage {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(weakSelf) strongSelf = self;
        
        UIImage *sourceImage = [UIImage imageNamed:@"image"];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        // CIImage
        CIImage *inputCIImage = [[CIImage alloc]initWithImage:sourceImage];
        // 过滤器
        CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        // 将图片输入到滤镜中
        [blurFilter setValue:inputCIImage forKey:kCIInputImageKey];
        // 设置模糊程度
        [blurFilter setValue:@(20) forKey:@"inputRadius"];
        // 将处理之后的图片输出
        CIImage *outCIImage = [blurFilter valueForKey:kCIOutputImageKey];
        // 获取CGImage句柄
        // createCGImage:处理过的CIImage
        // fromRect：如果从处理过得图片获取frame会比原图小，因此在此需要设置为原始的CIImage.frame
        CGImageRef outImageRef = [context createCGImage:outCIImage fromRect:[inputCIImage extent]];
        // 获取到最终图片
        UIImage *resultImage = [UIImage imageWithCGImage:outImageRef];
        // 释放句柄
        CGImageRelease(outImageRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.imageView.image = resultImage;
        });
    });
}

#pragma mark - 系统自带Effect
- (void)useSystemEffect {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
    visualEffectView.frame = CGRectMake(0, 0, CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame) / 2);
    [self.imageView addSubview:visualEffectView];
}

- (void)useImageEffect {
    self.imageView.image = [[UIImage imageNamed:@"image"]blurImageAtFrame:CGRectMake(10, 10, 100, 100)];
}

#pragma mark - GPUImage
- (void)useGPUImage {
    __weak typeof(self) weafSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 高斯模糊
        GPUImageGaussianBlurFilter *blurFile = [[GPUImageGaussianBlurFilter alloc]init];
        blurFile.blurRadiusInPixels = 10;
        UIImage *blurImage = [blurFile imageByFilteringImage:[UIImage imageNamed:@"image"]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weafSelf.imageView.image = blurImage;
        });
    });
}

#pragma mark - 添加模糊效果层
- (void)useFXBlurView {
    
    FXBlurView *fxView = [[FXBlurView alloc] initWithFrame:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    //动态
    fxView.dynamic = NO;
    //模糊范围
    fxView.blurRadius = 10;
    //背景色
    fxView.tintColor = [UIColor clearColor];
    [self.imageView addSubview:fxView];
}

@end
