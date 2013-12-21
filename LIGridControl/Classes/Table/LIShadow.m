//
//  LIShadow.m
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIShadow.h"

@implementation LIShadow

// lifecycle

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self setWantsLayer:YES];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
    }
    return self;
}

// properties

- (void)setShadowDirection:(LIShadowDirection)shadowDirection {
    if (_shadowDirection != shadowDirection) {
        _shadowDirection = shadowDirection;
        [self setNeedsDisplay:YES];
    }
}

// drawing

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
    
}

@end
