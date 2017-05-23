//
//  RYIndicatorBackgroudView.m
//  ZSSRichTextEditor
//
//  Created by luomeng on 2017/5/2.
//  Copyright © 2017年 Zed Said Studio. All rights reserved.
//

#import "RYIndicatorBackgroudView.h"

#define JKRadius 7
#define JKColor(r,g,b)     [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]


@interface RYIndicatorBackgroudView ()

@property(nonatomic, assign) float rectDistance;

@end

@implementation RYIndicatorBackgroudView



- (instancetype)initWithFrame:(CGRect)frame withRightDistance:(float)distance{

    if (self = [super initWithFrame:frame]) {
      
        self.rectDistance = distance;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    self.backgroundColor = [UIColor whiteColor];
    CGContextRef context = UIGraphicsGetCurrentContext();

    drawBg(context, rect, self.rectDistance);
}

void drawBg(CGContextRef context, CGRect rect, float rightDistance){
    
    //左上角四分之一圆
    CGFloat topX = 7;
    CGFloat topY = 7;
    
    CGFloat topRadius = JKRadius;
    CGContextAddArc(context, topX, topY, topRadius, M_PI, 3 / 2.0 * M_PI , 0);
    
    //向右延伸,画上面那条横线
    CGContextAddLineToPoint(context, rect.size.width - JKRadius, 0);
    
  
    //右上角四分之一圆
    CGContextAddArc(context, rect.size.width - JKRadius, topY, topRadius, 3 / 2.0 * M_PI, 2.0 * M_PI , 0);
    
    //向下延伸,画右面那条竖线
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height - 9 - 7);
    
    //右下角四分之一圆
    CGContextAddArc(context, rect.size.width - JKRadius, rect.size.height - 9 - 7, topRadius, 2.0 * M_PI, M_PI / 2.0 , 0);
    
    if (rightDistance > 0) {
        
        CGContextAddLineToPoint(context, rect.size.width - rightDistance, rect.size.height - 9);
        
        CGContextAddLineToPoint(context, rect.size.width - rightDistance - 17 / 2.0, rect.size.height);
        
        CGContextAddLineToPoint(context, rect.size.width - rightDistance - 17, rect.size.height - 9);
    }
    else{
    
        CGContextAddLineToPoint(context, rect.size.width / 2.0  + 17 / 2.0, rect.size.height - 9);
        
        CGContextAddLineToPoint(context, rect.size.width / 2.0, rect.size.height);
        
        CGContextAddLineToPoint(context, rect.size.width / 2.0 - 17 / 2.0, rect.size.height - 9);
    }
    
    CGContextAddLineToPoint(context, 7, rect.size.height - 9);

    //左下四分之一圆
    CGContextAddArc(context, 7, rect.size.height - 9 - 7, topRadius, M_PI / 2.0, M_PI, 0);

    //合并路径
    CGContextClosePath(context);
    
    //设置这颜色
    [JKColor(74,189,204) set];
    //显示
//        CGContextStrokePath(context);
    CGContextFillPath(context);
    
}


@end
