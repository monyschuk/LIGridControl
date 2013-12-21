//
//  LIShadow.m
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIShadow.h"

#import <QuartzCore/QuartzCore.h>

@implementation LIShadow {
    CAShapeLayer    *mask;
    CAGradientLayer *gradient;
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self setWantsLayer:YES];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
    }
    return self;
}

#pragma mark -
#pragma mark Properties

- (void)setShadowDirection:(LIShadowDirection)shadowDirection {
    if (_shadowDirection != shadowDirection) {
        _shadowDirection = shadowDirection;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return NO;
}
- (BOOL)isFlipped {
    return YES;
}
- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    NSRect layerBounds = self.layer.bounds;

    if (gradient == nil) {
        gradient = [CAGradientLayer layer];
        
        NSColor *fromColor = [NSColor colorWithCalibratedWhite:0 alpha:0.25];
        NSColor *toColor   = [NSColor colorWithCalibratedWhite:0 alpha:0.00];
        
        [gradient setColors:@[(id)fromColor.CGColor, (id)toColor.CGColor]];
        
        [self.layer addSublayer:gradient];
        
        mask = [CAShapeLayer layer];
        
        [gradient setMask:mask];
    }
    
    [self updateGradientInRect:layerBounds];
    [self updateMaskInRect:layerBounds];
}

- (void)updateGradientInRect:(NSRect)frameRect {
    [gradient setFrame:frameRect];
    
    switch (self.shadowDirection) {
        case LIShadowDirection_Up:
            [gradient setStartPoint:CGPointMake(0, 1)];
            [gradient setEndPoint:CGPointMake(0, 0)];
            break;
            
        case LIShadowDirection_Down:
            [gradient setStartPoint:CGPointMake(0, 0)];
            [gradient setEndPoint:CGPointMake(0, 1)];
            break;
            
        case LIShadowDirection_Left:
            [gradient setStartPoint:CGPointMake(1, 0)];
            [gradient setEndPoint:CGPointMake(0, 0)];
            break;
            
        case LIShadowDirection_Right:
            [gradient setStartPoint:CGPointMake(0, 0)];
            [gradient setEndPoint:CGPointMake(1, 0)];
            break;
    }
}

- (void)updateMaskInRect:(NSRect)frameRect {
    CGFloat minx = CGRectGetMinX(frameRect);
    CGFloat maxx = CGRectGetMaxX(frameRect);
    CGFloat midx = CGRectGetMidX(frameRect);
    CGFloat w    = CGRectGetWidth(frameRect);
    
    CGFloat miny = CGRectGetMinY(frameRect);
    CGFloat maxy = CGRectGetMaxY(frameRect);
    CGFloat midy = CGRectGetMidY(frameRect);
    CGFloat h    = CGRectGetHeight(frameRect);
    
    // our mask is an arced path
    CGMutablePathRef path = CGPathCreateMutable();
    
    switch (self.shadowDirection) {
        case LIShadowDirection_Up:
            CGPathMoveToPoint(path, NULL, minx, maxy);
            CGPathAddLineToPoint(path, NULL, minx, maxy-1);
            CGPathAddCurveToPoint(path, NULL, midx, maxy-(2*h), midx, maxy-(2*h), maxx, maxy-1);
            CGPathAddLineToPoint(path, NULL, maxx, maxy);
            CGPathCloseSubpath(path);
            break;
            
        case LIShadowDirection_Down:
            CGPathMoveToPoint(path, NULL, minx, miny);
            CGPathAddLineToPoint(path, NULL, minx, miny+1);
            CGPathAddCurveToPoint(path, NULL, midx, miny+(2*h), midx, miny+(2*h), maxx, miny+1);
            CGPathAddLineToPoint(path, NULL, maxx, miny);
            CGPathCloseSubpath(path);
            break;
            
        case LIShadowDirection_Left:
            CGPathMoveToPoint(path, NULL, maxx, miny);
            CGPathAddLineToPoint(path, NULL, maxx-1, miny);
            CGPathAddCurveToPoint(path, NULL, maxx-(2*w), midy, maxx-(2*w), midy, maxx-1, maxy);
            CGPathAddLineToPoint(path, NULL, maxx, maxy);
            CGPathCloseSubpath(path);
            break;
            
        case LIShadowDirection_Right:
            CGPathMoveToPoint(path, NULL, minx, miny);
            CGPathAddLineToPoint(path, NULL, minx+1, miny);
            CGPathAddCurveToPoint(path, NULL, minx+(2*w), midy, minx+(2*w), midy, minx+1, maxy);
            CGPathAddLineToPoint(path, NULL, minx, maxy);
            CGPathCloseSubpath(path);
            break;
    }
    
    mask.path = path;
    
    CGPathRelease(path);
}

@end
