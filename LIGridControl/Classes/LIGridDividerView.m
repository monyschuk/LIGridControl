//
//  LIGridDivider.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridDividerView.h"

@implementation LIGridDividerView

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureGridDivider];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureGridDivider];
}

- (void)configureGridDivider {
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    
    _backgroundColor = [[NSColor gridColor] copy];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor.copy;
        
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}
- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}

@end
