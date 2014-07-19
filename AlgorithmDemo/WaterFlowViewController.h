//
//  WaterFlowViewController.h
//  WaterFlowDemo
//
//  Created by 白 浩泉 on 13-9-28.
//  Copyright (c) 2013年 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    NormalSchema = 0,
    SortedSchema,
    DPSchema,
} WaterFlowArrangeSchema;

@interface WaterFlowViewController : UIViewController

@property (nonatomic) WaterFlowArrangeSchema schema;
- (id)initWithSchema:(WaterFlowArrangeSchema)schema;

@end
