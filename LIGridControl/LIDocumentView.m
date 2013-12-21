//
//  LIDocumentView.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 2013-12-21.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIDocumentView.h"

@implementation LIDocumentView

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
}

@end
