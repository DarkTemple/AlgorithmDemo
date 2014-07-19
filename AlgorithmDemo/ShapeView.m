//
//  ShapeView.m
//  Regulife
//
//  Created by 白 浩泉 on 14-4-9.
//  Copyright (c) 2014年 DaYuan. All rights reserved.
//

#import "ShapeView.h"

@interface ShapeView ()
@property (nonatomic) ShapeType type;
@property (nonatomic, strong) UIColor *color;
@end

@implementation ShapeView

- (id)initWithFrame:(CGRect)frame color:(UIColor *)color andType:(ShapeType)type
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        _color = color;
        _type = type;
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    if (self.type == ShapeCircule)
    {
        CGContextAddEllipseInRect(context, CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)));
    }
    else if (self.type == ShapeTriangle)
    {
        CGContextMoveToPoint(context, 0, CGRectGetHeight(self.frame));
        CGContextAddLineToPoint(context, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        CGContextAddLineToPoint(context, CGRectGetWidth(self.frame)/2, 0);
        CGContextAddLineToPoint(context, 0, CGRectGetHeight(self.frame));
    }
    
    CGContextFillPath(context);
}


@end
