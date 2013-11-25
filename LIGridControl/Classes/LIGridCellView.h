//
//  LIGridCellView.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIGridCellViewVerticalAlignment_Top,
    LIGridCellViewVerticalAlignment_Center,
    LIGridCellViewVerticalAlignment_Bottom
} LIGridCellViewVerticalAlignment;

@interface LIGridCellView : NSTextField

@property(nonatomic, getter=isVertical) BOOL vertical;
@property(nonatomic) LIGridCellViewVerticalAlignment verticalAlignment;

@end

@interface LIGridCell : NSTextFieldCell

#pragma mark -
#pragma mark Layout

- (NSRect)textFrameWithFrame:(NSRect)aRect;

@property(nonatomic, getter=isVertical) BOOL vertical;
@property(nonatomic) LIGridCellViewVerticalAlignment verticalAlignment;

@end
