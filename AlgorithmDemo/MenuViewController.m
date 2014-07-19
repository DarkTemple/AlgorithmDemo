//
//  MenuViewController.m
//  AlgorithmDemo
//
//  Created by Haoquan Bai on 14-6-27.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import "MenuViewController.h"
#import "DictSearchViewController.h"
#import "WaterFlowViewController.h"
#import "PointClusterViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)gotoBinarySearchDemo:(id)sender
{
    DictSearchViewController *dictSearchViewController = [[DictSearchViewController alloc] init];
    [self.navigationController pushViewController:dictSearchViewController animated:YES];
}

- (IBAction)gotoDPDemo:(id)sender
{
    UISegmentedControl *segmentCtrl = (UISegmentedControl *)sender;
    
    WaterFlowViewController *waterFlowViewController = [[WaterFlowViewController alloc] initWithSchema:(WaterFlowArrangeSchema)segmentCtrl.selectedSegmentIndex];
    [self.navigationController pushViewController:waterFlowViewController animated:YES];
}

- (IBAction)gotoDisjointSetDemo:(id)sender
{
    PointClusterViewController *pointClusterViewController = [[PointClusterViewController alloc] init];
    [self.navigationController pushViewController:pointClusterViewController animated:YES];
}

@end
