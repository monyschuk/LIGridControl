//
//  LIGridSelection.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 12/11/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LIGridControl, LIGridArea;
@interface LIGridSelection : NSObject

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column gridControl:(LIGridControl *)gridControl;

@property(readonly, nonatomic) NSUInteger row, column;
@property(readonly, nonatomic, copy) LIGridArea *gridArea;
@property(readonly, nonatomic, weak) LIGridControl *gridControl;

typedef enum {
    LIDirection_Up,
    LIDirection_Down,
    LIDirection_Left,
    LIDirection_Right
} LIDirection;

#pragma mark -
#pragma mark Editing

- (LIGridArea *)editingArea;

#pragma mark -
#pragma mark Selection Movement

- (LIGridSelection *)selectionByMovingInDirection:(LIDirection)direction;

#pragma mark -
#pragma mark Selection Resize

- (LIGridSelection *)selectionByResizingInDirection:(LIDirection)direction;

@end
