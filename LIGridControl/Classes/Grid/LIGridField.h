//
//  LIGridField.h
//  LIGrid
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIGridFieldVerticalAlignment_Top,
    LIGridFieldVerticalAlignment_Center,
    LIGridFieldVerticalAlignment_Bottom
} LIGridFieldVerticalAlignment;

@interface LIGridField : NSTextField

@property(nonatomic, getter=isVertical) BOOL vertical;
@property(nonatomic) LIGridFieldVerticalAlignment verticalAlignment;

@end

@interface LIGridFieldCell : NSTextFieldCell

- (void)configureGridCell;

#pragma mark -
#pragma mark Layout

- (NSRect)textFrameWithFrame:(NSRect)aRect;

@property(nonatomic, getter=isVertical) BOOL vertical;
@property(nonatomic) LIGridFieldVerticalAlignment verticalAlignment;

@end
