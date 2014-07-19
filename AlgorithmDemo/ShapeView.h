//
//  ShapeView.h
//  Regulife
//
//  Created by 白 浩泉 on 14-4-9.
//  Copyright (c) 2014年 DaYuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ShapeCircule,
    ShapeTriangle,
} ShapeType;

@interface ShapeView : UIView

- (id)initWithFrame:(CGRect)frame color:(UIColor *)color andType:(ShapeType)type;

@end
