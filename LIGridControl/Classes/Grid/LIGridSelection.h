//
//  LIGridSelection.h
//  LIGrid
//
//  Created by Mark Onyschuk on 12/11/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LIGrid, LIGridArea;
@interface LIGridSelection : NSObject

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column gridControl:(LIGrid *)gridControl;

@property(readonly, nonatomic) NSUInteger row, column;
@property(readonly, nonatomic, copy) LIGridArea *gridArea;
@property(readonly, nonatomic, weak) LIGrid *gridControl;

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

#pragma mark -
#pragma mark Containment Tests

- (BOOL)containsRow:(NSUInteger)row;
- (BOOL)containsColumn:(NSUInteger)column;
- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column;

#pragma mark -
#pragma mark Property List Representation

- (NSDictionary *)propertyListRepresentation;
- (id)initWithPropertyListRepresentation:(NSDictionary *)plist gridControl:(LIGrid *)gridControl;

@end
