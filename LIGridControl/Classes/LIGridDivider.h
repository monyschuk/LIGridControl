//
//  LIGridDividerView.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIGridDividerStyle_Single       = 1 << 0,
    LIGridDividerStyle_Double       = 1 << 1,
    
    LIGridDividerStyle_Solid        = 1 << 6,
    LIGridDividerStyle_Dotted       = 1 << 7,
    LIGridDividerStyle_Dashed       = 1 << 8
} LIGridDividerStyle;

@interface LIGridDivider : NSControl

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic) LIGridDividerStyle dividerStyle;

@end

@interface LIGridDividerCell : NSCell

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic) LIGridDividerStyle dividerStyle;

@end