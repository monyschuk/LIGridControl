//
//  LIGridArea.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"
#import "LIGridControl.h"

@implementation LIGridArea

+ (instancetype)areaWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object {
    return [[self alloc] initWithRowRange:NSMakeRange(row, 1) columnRange:NSMakeRange(column, 1) representedObject:object];
}

+ (instancetype)areaWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object {
    return [[self alloc] initWithRowRange:rowRange columnRange:columnRange representedObject:object];
}

- (id)initWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)representedObject {
    if ((self = [super init])) {
        _rowRange           = rowRange;
        _columnRange        = columnRange;
        _representedObject  = representedObject;
    }
    return self;
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[LIGridArea alloc] initWithRowRange:_rowRange columnRange:_columnRange representedObject:_representedObject];
}

#pragma mark -
#pragma mark Derived Properties

- (NSUInteger)row {
    return _rowRange.location;
}
- (NSUInteger)column {
    return _columnRange.location;
}

- (void)setRow:(NSUInteger)row {
    _rowRange = NSMakeRange(row, 1);
}
- (void)setColumn:(NSUInteger)column {
    _columnRange = NSMakeRange(column, 1);
}

- (NSUInteger)minRow {
    return _rowRange.location;
}
- (NSUInteger)minColumn {
    return _columnRange.location;
}
- (NSUInteger)maxRow {
    return NSMaxRange(_rowRange);
}
- (NSUInteger)maxColumn {
    return NSMaxRange(_columnRange);
}

- (NSIndexSet *)rowIndexes {
    return [[NSIndexSet alloc] initWithIndexesInRange:_rowRange];
}
- (NSIndexSet *)columnIndexes {
    return [[NSIndexSet alloc] initWithIndexesInRange:_columnRange];
}

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea {
    return [LIGridArea areaWithRowRange:NSUnionRange(_rowRange, otherArea.rowRange) columnRange:NSUnionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

#pragma mark -
#pragma mark Intersection

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea {
    return [LIGridArea areaWithRowRange:NSIntersectionRange(_rowRange, otherArea.rowRange) columnRange:NSIntersectionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column {
    return NSLocationInRange(row, _rowRange) && NSLocationInRange(column, _columnRange);
}

- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    return NSIntersectionRange(_rowRange, rowRange).length && NSIntersectionRange(_columnRange, columnRange).length;
}

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash {
    NSUInteger val;
    
    val  = _rowRange.location;      val <<= 11;
    val ^= _rowRange.length;        val <<= 11;
    val ^= _columnRange.location;   val <<= 10;
    val ^= _columnRange.length;
    
    return val;
}

- (BOOL)isEqual:(id)object {
    LIGridArea *other = object;
    return other != nil && NSEqualRanges(_rowRange, other->_rowRange) && NSEqualRanges(_columnRange, other->_columnRange);
}


#pragma mark -
#pragma mark Description

- (NSString *)description {
    id rr = (_rowRange.length == 1) ? @(_rowRange.location) : NSStringFromRange(_rowRange);
    id cr = (_columnRange.length == 1) ? @(_columnRange.location) : NSStringFromRange(_columnRange);
    
    return [NSString stringWithFormat:@"(r: %@, c: %@): ro = %@", rr, cr, _representedObject];
}

@end


@implementation LISelectionArea

- (id)initWithGridArea:(LIGridArea *)gridArea control:(LIGridControl *)gridControl {
    if ((self = [super initWithRowRange:gridArea.rowRange columnRange:gridArea.columnRange representedObject:nil])) {
        _gridArea       = gridArea;
        _gridControl    = gridControl;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LISelectionArea *copy = [super copyWithZone:zone];
    
    copy->_gridArea     = _gridArea;
    copy->_gridControl  = _gridControl;
    
    return copy;
}

// the selection edge to adjust
typedef enum {
    LISelectionEdge_Top,                // adjust the selection top edge
    LISelectionEdge_Left,               // etc...
    LISelectionEdge_Right,
    LISelectionEdge_Bottom
} LISelectionEdge;

- (BOOL)selectionExtendsUp {
    return (self.minRow < self.gridArea.minRow);
}
- (BOOL)selectionExtendsDown {
    return (self.maxRow > self.gridArea.maxRow);
}
- (BOOL)selectionExtendsLeft {
    return (self.minColumn < self.gridArea.minColumn);
}
- (BOOL)selectionExtendsRight {
    return (self.maxColumn > self.gridArea.maxColumn);
}

- (void)getSelectionEdge:(LISelectionEdge *)selectionEdgeP advancement:(NSInteger *)advancementP forAdvanceInDirection:(LIDirection)direction {
    switch (direction) {
        case LIDirection_Up:
            *advancementP   = -1;
            *selectionEdgeP = [self selectionExtendsDown] ? LISelectionEdge_Bottom : LISelectionEdge_Top;
            break;
            
        case LIDirection_Down:
            *advancementP   =  1;
            *selectionEdgeP = [self selectionExtendsUp] ? LISelectionEdge_Top : LISelectionEdge_Bottom;
            break;
            
        case LIDirection_Left:
            *advancementP   = -1;
            *selectionEdgeP = [self selectionExtendsRight] ? LISelectionEdge_Right : LISelectionEdge_Left;
            break;

        case LIDirection_Right:
            *advancementP   =  1;
            *selectionEdgeP = [self selectionExtendsLeft] ? LISelectionEdge_Left : LISelectionEdge_Right;
            break;
    }
}

- (LISelectionArea *)areaByAdvancingInDirection:(LIDirection)direction {
    LISelectionArea *copy = self.copy;

    LISelectionEdge edge;
    NSInteger       advancement;
    
    [self getSelectionEdge:&edge advancement:&advancement forAdvanceInDirection:direction];

    // attempt to add, or subtract cells within our test area.
    // if the test area contains spanning cells, then we expand
    // the test area until it contains no further unaccounted spanners.
    // we then add or subtract the resulting area and return this new area
    
    BOOL            add;
    LIGridArea      *testArea;

    if (advancement > 0) {
        switch (edge) {
            case LISelectionEdge_Top:
                add = NO;
                testArea = [LIGridArea areaWithRowRange:NSMakeRange(self.minRow, 1) columnRange:self.columnRange representedObject:nil];
                break;
                
            case LISelectionEdge_Left:
                add = NO;
                testArea = [LIGridArea areaWithRowRange:self.rowRange columnRange:NSMakeRange(self.minColumn, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Right:
                add = YES;
                testArea = [LIGridArea areaWithRowRange:self.rowRange columnRange:NSMakeRange(self.maxColumn, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Bottom:
                add = YES;
                testArea = [LIGridArea areaWithRowRange:NSMakeRange(self.maxRow, 1) columnRange:self.columnRange representedObject:nil];
                break;
        }
    } else {
        switch (edge) {
            case LISelectionEdge_Top:
                add = YES;
                testArea = [LIGridArea areaWithRowRange:NSMakeRange(self.minRow - 1, 1) columnRange:self.columnRange representedObject:nil];
                break;
                
            case LISelectionEdge_Left:
                add = YES;
                testArea = [LIGridArea areaWithRowRange:self.rowRange columnRange:NSMakeRange(self.minColumn - 1, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Right:
                add = NO;
                testArea = [LIGridArea areaWithRowRange:self.rowRange columnRange:NSMakeRange(self.maxColumn - 1, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Bottom:
                add = NO;
                testArea = [LIGridArea areaWithRowRange:NSMakeRange(self.maxRow - 1, 1) columnRange:self.columnRange representedObject:nil];
                break;
        }
    }

    LIGridArea  *expandedArea = nil;
    
    while (! [testArea isEqual:expandedArea]) {
        NSArray *enclosedFixedAreas = [self.gridControl fixedAreasInRowRange:testArea.rowRange columnRange:testArea.columnRange];

        if (expandedArea == nil) {
            expandedArea = testArea;
        } else {
            testArea     = expandedArea;
        }
        
        for (LIGridArea *fixedArea in enclosedFixedAreas) {
            expandedArea = [expandedArea unionArea:fixedArea];
        }
    }
    
    
    if (add) {
        copy.rowRange = NSUnionRange(copy.rowRange, expandedArea.rowRange);
        copy.columnRange = NSUnionRange(copy.columnRange, expandedArea.columnRange);
        
    } else {
        
    }
    return copy;
}

@end
