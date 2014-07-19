//
//  PointClusterViewController.m
//  AlgorithmDemo
//
//  Created by 白 浩泉 on 14-7-6.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import "PointClusterViewController.h"
#import "ShapeView.h"
#import "Algorithm.h"

static const double kNeighbourThreshold = 40;
static const double kClusterThreshold = 200;
static const CGFloat kPointSizeWidth = 6.f;
static const int kNumOfCluster = 4;
static const int kClusterCapacity = 10;
static const CGFloat kMinOriginX = 10;
static const CGFloat kMaxOriginX = 310;
static const CGFloat kMinOriginY = 10;
static const CGFloat kMaxOriginY = 480;

static NSArray * const kAnimColorArr = @[[UIColor redColor],
                                    [UIColor greenColor],
                                    [UIColor blueColor],
                                    [UIColor purpleColor]];

static inline double distanceBetweenTwoPoints(CGPoint a, CGPoint b)
{
    return sqrt(pow((a.x - b.x), 2) + pow((a.y - b.y), 2));
}

static inline BOOL isNeighbourWithInDistance(CGPoint a, CGPoint b, double neighbourDistance)
{
    return (distanceBetweenTwoPoints(a, b) <= neighbourDistance);
}

static inline double randInRange(double start, double end)
{
    double ratio = (double)rand() / RAND_MAX;
    return start + (end - start) * ratio;
}

static inline CGPoint genRandomPointInRectWithWidth(CGRect rect, CGFloat width)
{
    CGFloat x = randInRange(MAX(kMinOriginX, CGRectGetMinX(rect)), MIN(kMaxOriginX, CGRectGetMaxX(rect)));
    CGFloat y = randInRange(MAX(kMinOriginY, CGRectGetMinY(rect)), MIN(kMaxOriginY, CGRectGetMaxY(rect)));
    CGPoint retPoint = CGPointMake(x, y);
    if (x < 0 || y < 0) {
        retPoint = genRandomPointInRectWithWidth(rect, width);
    }
    
    return retPoint;
}

static inline CGPoint getAverCenterOfCluster(NSArray *points)
{
    CGPoint center = CGPointZero;
    for (NSValue *pointVal in points) {
        center.x += [pointVal CGPointValue].x;
        center.y += [pointVal CGPointValue].y;
    }
    
    center.x /= points.count;
    center.y /= points.count;
    return center;
}

@interface PointClusterViewController ()

@property (nonatomic, strong) NSMutableDictionary *pointTable;
@property (nonatomic, strong) NSMutableDictionary *clusterTable;

@end

@implementation PointClusterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _pointTable = [NSMutableDictionary dictionary];
        _clusterTable = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"cluster" style:UIBarButtonItemStylePlain target:self action:@selector(doClustering:)];
    
    srand((unsigned)time(NULL));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self randomInitCluster];
    
    for (id key in self.pointTable) {
        CGPoint point = [self.pointTable[key] CGPointValue];
        ShapeView *subView = [[ShapeView alloc] initWithFrame:CGRectMake(0, 0, kPointSizeWidth, kPointSizeWidth) color:[UIColor redColor] andType:ShapeTriangle];
        subView.center = point;
        [self.view addSubview:subView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)startAnimationOnView:(UIView *)view atPoint:(CGPoint)point withColor:(UIColor *)color
{
    UIView *waveView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 77, 77)];
    waveView1.center = point;
    waveView1.layer.cornerRadius = CGRectGetWidth(waveView1.frame) / 2.0f;
    waveView1.backgroundColor = color;
    waveView1.alpha = 0.1;
    [view addSubview:waveView1];
    
    NSNumber *fromAlpha = @.77f;
    NSNumber *toScale = @2.17f;
    CFTimeInterval duration = 1.7f;
    
    CAAnimationGroup *waveAnimation1 = [CAAnimationGroup animation];
    CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnim.fromValue = fromAlpha;
    opacityAnim.toValue = @0;
    opacityAnim.duration = duration;
    
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @.17;
    scaleAnim.toValue = toScale;
    scaleAnim.duration = duration;
    
    waveAnimation1.animations = @[opacityAnim, scaleAnim];
    waveAnimation1.duration = duration;
    waveAnimation1.removedOnCompletion = YES;
    waveAnimation1.fillMode = kCAFillModeForwards;
    [waveAnimation1 setValue:@"wave1" forKey:@"animTag"];
    waveAnimation1.delegate = self;
    
    waveAnimation1.repeatCount = HUGE_VALF;
    [waveView1.layer addAnimation:waveAnimation1 forKey:@"wave1"];
}

- (void)randomInitCluster
{
    NSMutableArray *clusterCenterArr = [NSMutableArray arrayWithCapacity:kNumOfCluster];
    while (clusterCenterArr.count < kNumOfCluster) {
        CGPoint randCenterPoint = genRandomPointInRectWithWidth(CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)), kPointSizeWidth);
        BOOL isValidNewCenter = YES;
        for (NSValue *centerVal in clusterCenterArr) {
            CGPoint centerPoint = [centerVal CGPointValue];
            if (isNeighbourWithInDistance(centerPoint, randCenterPoint, kClusterThreshold)) {
                isValidNewCenter = NO;
                break;
            }
        }
        
        if (isValidNewCenter) {
            [clusterCenterArr addObject:[NSValue valueWithCGPoint:randCenterPoint]];
            // add cluster member point
            NSMutableArray *clusterMemberArr = [NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:randCenterPoint]];
            for (int i=0; i<kClusterCapacity; i++) {
                CGPoint point = [clusterMemberArr[rand()%clusterMemberArr.count] CGPointValue];
                BOOL isValidMember = NO;
                CGPoint newPoint;
                do {
                    CGRect rect = CGRectMake(point.x-kNeighbourThreshold/2,
                                             point.y-kNeighbourThreshold/2,
                                             kNeighbourThreshold,
                                             kNeighbourThreshold);
                    newPoint = genRandomPointInRectWithWidth(rect, kNeighbourThreshold);
                    isValidMember = isNeighbourWithInDistance(newPoint, point, kNeighbourThreshold);
                } while (!isValidMember);
                
                [clusterMemberArr addObject:[NSValue valueWithCGPoint:newPoint]];
            }
            
            for (NSValue *pointVal in clusterMemberArr) {
                [self.pointTable setObject:pointVal forKey:[NSNumber numberWithUnsignedInteger:(self.pointTable.count)]];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doClustering:(id)sender
{
    // generate the neighbour pair within n^2 time
    std::vector<std::pair<uint32_t, uint32_t> > neighbourPairVec;

    for (int i=0; i<self.pointTable.count; i++) {
        for (int j=i+1; j<self.pointTable.count; j++) {
            CGPoint a = [self.pointTable[[NSNumber numberWithInt:i]] CGPointValue];
            CGPoint b = [self.pointTable[[NSNumber numberWithInt:j]] CGPointValue];
            if (isNeighbourWithInDistance(a, b, kNeighbourThreshold)) {
                neighbourPairVec.push_back(std::make_pair(i, j));
            }
        }
    }
    
    // use disjoint-set union
    int pointCount = (int)self.pointTable.count;
    Algorithm::DisJointSet disJointSet(pointCount);
    for (int i=0; i<neighbourPairVec.size(); i++) {
        disJointSet.UnionSet(neighbourPairVec[i].first, neighbourPairVec[i].second);
    }
    
    int x = disJointSet.GetNumOfIsolatedSet();
    NSLog(@"%d", x);
    
    disJointSet.PrintTable();
    
    // clusting done, make cluster dic and draw center.
    for (int i=0; i<self.pointTable.count; i++) {
        uint32_t parentId = disJointSet.FindParent(i);
        NSMutableArray *memberArr = self.clusterTable[[NSNumber numberWithInt:parentId]];
        if (!memberArr) {
            memberArr = [NSMutableArray array];
            self.clusterTable[[NSNumber numberWithInt:parentId]] = memberArr;
        }
        
        [memberArr addObject:self.pointTable[[NSNumber numberWithInt:i]]];
    }
    
    NSLog(@"%@", self.clusterTable);
    
    int counter = 0;
    for (id key in self.clusterTable) {
        CGPoint center = getAverCenterOfCluster(self.clusterTable[key]);
        [self startAnimationOnView:self.view atPoint:center withColor:kAnimColorArr[counter++]];
    }
}

@end
