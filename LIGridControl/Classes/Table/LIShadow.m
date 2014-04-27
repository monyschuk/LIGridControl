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

- (void)setShadowColor:(NSColor *)shadowColor {
    if (_shadowColor != shadowColor) {
        _shadowColor = [shadowColor copy];
        [self setNeedsDisplay:YES];
    }
}

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
        
        NSColor *fromColor = self.shadowColor ? self.shadowColor : [NSColor colorWithCalibratedWhite:0 alpha:0.25];
        NSColor *toColor   = [NSColor colorWithCalibratedWhite:0 alpha:0.00];
        
        [gradient setColors:@[(id)fromColor.CGColor, (id)toColor.CGColor]];
        
        [self.layer addSublayer:gradient];

        [self updateGradientInRect:layerBounds];
    }

    [gradient setFrame:layerBounds];
}

- (void)updateGradientInRect:(NSRect)frameRect {
    
    NSColor *fromColor = self.shadowColor ? self.shadowColor : [NSColor colorWithCalibratedWhite:0 alpha:0.15];
    NSColor *toColor   = [NSColor colorWithCalibratedWhite:0 alpha:0.00];

    [gradient setColors:@[(id)fromColor.CGColor, (id)toColor.CGColor]];
    
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

@end
