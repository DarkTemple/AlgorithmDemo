//
//  WaterFlowViewController.m
//  WaterFlowDemo
//
//  Created by 白 浩泉 on 13-9-28.
//  Copyright (c) 2013年 Test. All rights reserved.
//

#import "WaterFlowViewController.h"
#import "Config.h"
#import "Algorithm.h"

static inline int compareHeight(const void* p1, const void* p2)
{
    return (*(int *)p1 < *(int *)p2);
}

@interface WaterFlowViewController ()
{
    int heightArr[10000];
}

@property (nonatomic, retain) UIScrollView *contentView;
@property (nonatomic, retain) UIButton *loadMoreButton;
@property (nonatomic) int leftHeight;
@property (nonatomic) int rightHeight;
@property (nonatomic) int pageCount;
@property (nonatomic) int totalDiff;
@end

@implementation WaterFlowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (id)initWithSchema:(WaterFlowArrangeSchema)schema
{
    if (self = [super init]) {
        _schema = schema;
    }
    
    return self;
}

- (UIButton *)loadMoreButton
{
    if (!_loadMoreButton) {
        _loadMoreButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
        [_loadMoreButton setTitle:@"点击加载更多..." forState:UIControlStateNormal];
        [_loadMoreButton addTarget:self action:@selector(loadMoreImages:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _loadMoreButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.contentView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.contentView setBackgroundColor:[UIColor grayColor]];
    [self.contentView addSubview:self.loadMoreButton];
    [self.view addSubview:self.contentView];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"testData" ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempArr = [content componentsSeparatedByString:@"\n"];
    for (int i=0; i<tempArr.count; i++) {
        heightArr[i] = [tempArr[i] intValue];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.contentView.frame = self.view.frame;
    [self loadMoreImages:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadMoreImages:(id)sender
{
    int curHeightArr[kPageSize];
    for (int i=0; i<kPageSize; i++) {
        curHeightArr[i] = heightArr[kPageSize*self.pageCount+i];
    }
    
    if (self.schema == DPSchema) {
        int leftItemArr[kPageSize];
        int retLen = 0;
        int wantedSum = (Algorithm::sumOfArr(curHeightArr, kPageSize) +
                         (self.rightHeight - self.leftHeight)) / 2;
        
        // to reduce time complexity, quant by 10
        int quantedHeightArr[kPageSize];
        int quantedWantedSum = round((double)wantedSum / kQuantLevel);
        for (int i=0; i<kPageSize; i++) {
            quantedHeightArr[i] = round((double)curHeightArr[i] / kQuantLevel);
        }
        
        Algorithm::dpSol(quantedHeightArr, kPageSize, quantedWantedSum, leftItemArr, retLen);
        int indexInLeft = 0;
        int indexAll = 0;
        int originX = 0, originY = 0;
        while (indexAll < kPageSize) {
            int imgHeight = curHeightArr[indexAll];
            if (indexInLeft < retLen && indexAll == leftItemArr[indexInLeft]) {
                originX = 2;
                originY = self.leftHeight;
                self.leftHeight += imgHeight;
                indexInLeft++;
            } else {
                originX = 161;
                originY = self.rightHeight;
                self.rightHeight += imgHeight;
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 157, imgHeight)];
            [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", (rand()%kImageResourceCount)+1]]];
            imageView.layer.borderWidth = 1;
            imageView.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:imageView];
            self.contentView.contentSize = CGSizeMake(0, MAX(self.leftHeight, self.rightHeight) + 44.f);
            indexAll++;
        }
    } else {
        if (self.schema == SortedSchema) {
            qsort(curHeightArr, kPageSize, sizeof(curHeightArr[0]), compareHeight);
        }
        
        int originX = 0, originY = 0;
        for (int i=0; i<kPageSize; i++) {
            int imgHeight = curHeightArr[i];
            if (self.leftHeight <= self.rightHeight) {
                originX = 2;
                originY = self.leftHeight;
                self.leftHeight += imgHeight;
            } else {
                originX = 161;
                originY = self.rightHeight;
                self.rightHeight += imgHeight;
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 157, imgHeight)];
            [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", (rand()%kImageResourceCount)+1]]];
            imageView.layer.borderWidth = 1;
            imageView.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:imageView];
            self.contentView.contentSize = CGSizeMake(0, MAX(self.leftHeight, self.rightHeight) + 44.f);
        }
    }

    [self.loadMoreButton setFrame:CGRectMake(0, MAX(self.leftHeight, self.rightHeight), CGRectGetWidth(self.view.frame), 44)];
    
    // show statistics info
    self.pageCount++;
    self.totalDiff += abs(self.leftHeight-self.rightHeight);
    self.title = [NSString stringWithFormat:@"Page: %d, total gap is %d", self.pageCount, self.totalDiff];
}

@end
