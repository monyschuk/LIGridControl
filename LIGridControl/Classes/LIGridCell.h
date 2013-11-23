//
//  LIGridCell.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIGridCellVerticalAlignment_Top,
    LIGridCellVerticalAlignment_Center,
    LIGridCellVerticalAlignment_Bottom
} LIGridCellVerticalAlignment;

@interface LIGridCell : NSTextFieldCell

#pragma mark -
#pragma mark Layout

- (NSRect)textFrameWithFrame:(NSRect)aRect;

@property(nonatomic, getter=isVertical) BOOL vertical;
@property(nonatomic) LIGridCellVerticalAlignment verticalAlignment;

@end
