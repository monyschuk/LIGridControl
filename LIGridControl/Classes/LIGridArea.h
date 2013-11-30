//
//  LIGridArea.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LIGridArea : NSObject <NSCopying>

+ (instancetype)areaWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object;
+ (instancetype)areaWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object;

- (id)initWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object;

@property(nonatomic) NSUInteger row, column;
@property(nonatomic) NSRange rowRange, columnRange;

@property(readonly, nonatomic) NSUInteger minRow, maxRow, minColumn, maxColumn;
@property(readonly, nonatomic, weak) NSIndexSet *rowIndexes, *columnIndexes;

@property(nonatomic, strong) id representedObject;

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea;

#pragma mark -
#pragma mark Intersection

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea;

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column;
- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end

// LISelectionArea represents a grid area that can be transformed into a new grid area
// when it is extended in a given direction - up, down, left, or right. The object maintains
// a reference to its associated grid, and uses that reference to search for spanning
// cells when it is transformed.
//
// NOTE: the whole business of selection is straightforward for basic grids whose
// cells all span single rows and column. Once spanning cells are introduced however,
// then selection becomes more complicated. LISelectionArea encapsulates this complexity.

typedef enum {
    LIDirection_Up,
    LIDirection_Down,
    LIDirection_Left,
    LIDirection_Right
} LIDirection;

@class LIGridControl;
@interface LISelectionArea : LIGridArea

- (id)initWithGridArea:(LIGridArea *)gridArea control:(LIGridControl *)gridControl;

@property(readonly, nonatomic, strong) LIGridArea   *gridArea;
@property(readonly, nonatomic, weak) LIGridControl  *gridControl;

- (LISelectionArea *)areaByAdvancingInDirection:(LIDirection)direction;

@end