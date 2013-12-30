//
//  LIGridDivider.m
//  LIGrid
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridDivider.h"

@implementation LIGridDivider

+ (Class)cellClass {
    return [LIGridDividerCell class];
}

- (NSColor *)dividerColor {
    return [self.cell dividerColor];
}
- (void)setDividerColor:(NSColor *)dividerColor {
    [self.cell setDividerColor:dividerColor];
}

- (LIGridDividerStyle)dividerStyle {
    return [(LIGridDividerCell *)self.cell dividerStyle];
}
- (void)setDividerStyle:(LIGridDividerStyle)dividerStyle {
    [(LIGridDividerCell *)self.cell setDividerStyle:dividerStyle];
}

@end

@implementation LIGridDividerCell

#pragma mark -
#pragma mark Lifecycle

- (id)initTextCell:(NSString *)stringValue {
    if ((self = [super initTextCell:stringValue])) {
        _dividerColor = [NSColor gridColor];
        _dividerStyle = LIGridDividerStyle_Dashed|LIGridDividerStyle_Double;
    }
    return self;
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LIGridDividerCell *copy = [super copyWithZone:zone];

    copy->_dividerStyle = _dividerStyle;
    copy->_dividerColor = [_dividerColor copyWithZone:zone];
    
    return copy;
}

#pragma mark -
#pragma mark Properties

- (void)setDividerColor:(NSColor *)dividerColor {
    if (_dividerColor != dividerColor) {
        _dividerColor = [dividerColor copy];
        
        [self.controlView setNeedsDisplay:YES];
    }
}

- (void)setDividerStyle:(LIGridDividerStyle)dividerStyle {
    if (_dividerStyle != dividerStyle) {
        _dividerStyle = dividerStyle;
        
        [self.controlView setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing

- (void)drawWithFrame:(NSRect)frameRect inView:(NSView *)controlView {
    CGFloat w;
    NSPoint p0, p1;

    if (NSWidth(frameRect) < NSHeight(frameRect)) {
        w  = NSWidth(frameRect);
        p0 = NSMakePoint(NSMidX(frameRect), NSMinY(frameRect));
        p1 = NSMakePoint(NSMidX(frameRect), NSMaxY(frameRect));
    } else {
        w  = NSHeight(frameRect);
        p0 = NSMakePoint(NSMinX(frameRect), NSMidY(frameRect));
        p1 = NSMakePoint(NSMaxX(frameRect), NSMidY(frameRect));
    }
        
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextMoveToPoint(ctx, p0.x, p0.y);
    CGContextAddLineToPoint(ctx, p1.x, p1.y);

    CGContextSetStrokeColorWithColor(ctx, self.dividerColor.CGColor);
    CGContextSetLineWidth(ctx, w);

    CGContextStrokePath(ctx);
}
@end