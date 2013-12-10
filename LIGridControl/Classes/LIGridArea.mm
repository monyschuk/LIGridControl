//
//  LIGridArea.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"
#import "LIGridControl.h"

#include "grid.h"

using namespace li::grid;

@implementation LIGridArea

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object {
    return [self initWithRowRange:NSMakeRange(row, 0) columnRange:NSMakeRange(column, 0) representedObject:object];
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
    return [[[self class] alloc] initWithRowRange:_rowRange columnRange:_columnRange representedObject:_representedObject];
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
    _rowRange = NSMakeRange(row, 0);
}
- (void)setColumn:(NSUInteger)column {
    _columnRange = NSMakeRange(column, 0);
}

- (NSUInteger)maxRow {
    return NSMaxRange(_rowRange);
}
- (NSUInteger)maxColumn {
    return NSMaxRange(_columnRange);
}

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea {
    return [[LIGridArea alloc] initWithRowRange:NSUnionRange(_rowRange, otherArea.rowRange) columnRange:NSUnionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

#pragma mark -
#pragma mark Intersection

static BOOL rangeIntersectsRange(NSRange range, NSRange otherRange) {
    struct range r1 = range;
    struct range r2 = otherRange;
    
    return r1.intersects(r2);
}
- (BOOL)intersectsArea:(LIGridArea *)otherArea {
    return rangeIntersectsRange(_rowRange, otherArea->_rowRange) && rangeIntersectsRange(_columnRange, otherArea->_columnRange);
}

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea {
    return [[LIGridArea alloc] initWithRowRange:NSIntersectionRange(_rowRange, otherArea.rowRange) columnRange:NSIntersectionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column {
    struct range rr = _rowRange;
    struct range cr = _columnRange;
    
    return rr.contains(row) && cr.contains(column);
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
    id rr = (_rowRange.length == 0) ? @(_rowRange.location) : NSStringFromRange(_rowRange);
    id cr = (_columnRange.length == 0) ? @(_columnRange.location) : NSStringFromRange(_columnRange);
    
    return [NSString stringWithFormat:@"%@ (r: %@, c: %@): ro = %@", NSStringFromClass([self class]), rr, cr, _representedObject];
}

@end


@implementation LISelectionArea

- (id)initWithGridArea:(LIGridArea *)gridArea control:(LIGridControl *)gridControl {
    LIGridArea *effectiveArea = [gridControl areaAtRow:gridArea.row column:gridArea.column];
    if ((self = [super initWithRowRange:effectiveArea.rowRange columnRange:effectiveArea.columnRange representedObject:nil])) {
        _gridArea       = effectiveArea;
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

#pragma mark -
#pragma mark Area Movement

- (LISelectionArea *)areaByMovingInDirection:(LIDirection)direction {
    NSUInteger nextRow, nextCol;
    switch (direction) {
        case LIDirection_Up:
            nextRow = (self.gridArea.row > 0) ? self.gridArea.row - 1 : self.gridArea.row;
            nextCol = self.gridArea.column;
            break;
        case LIDirection_Down:
            nextRow = self.gridArea.maxRow;
            nextCol = self.gridArea.column;
            break;
        case LIDirection_Left:
            nextCol = (self.gridArea.column > 0) ? self.gridArea.column - 1 : self.gridArea.column;
            nextRow = self.gridArea.row;
            break;
        case LIDirection_Right:
            nextCol = self.gridArea.maxColumn;
            nextRow = self.gridArea.row;
            break;
    }
    
    NSUInteger numRows = self.gridControl.numberOfRows;
    NSUInteger numCols = self.gridControl.numberOfColumns;
    
    if (nextRow >= numRows) nextRow = numRows - 1;
    if (nextCol >= numCols) nextCol = numCols - 1;
    
    return [[LISelectionArea alloc] initWithGridArea:[self.gridControl areaAtRow:nextRow column:nextCol] control:self.gridControl];
}

#pragma mark -
#pragma mark Area Extension

typedef enum {
    LIAreaEdge_Top,
    LIAreaEdge_Left,
    LIAreaEdge_Right,
    LIAreaEdge_Bottom
} LIAreaEdge;

- (BOOL)selectionExtendsUp {
    return (self.row < self.gridArea.row);
}
- (BOOL)selectionExtendsDown {
    return (self.maxRow > self.gridArea.maxRow);
}
- (BOOL)selectionExtendsLeft {
    return (self.column < self.gridArea.column);
}
- (BOOL)selectionExtendsRight {
    return (self.maxColumn > self.gridArea.maxColumn);
}

- (void)getSelectionEdge:(LIAreaEdge *)areaEdgeP change:(NSInteger *)changeP forResizeInDirection:(LIDirection)direction {
    switch (direction) {
        case LIDirection_Up:
            *changeP = -1;
            *areaEdgeP = [self selectionExtendsDown] ? LIAreaEdge_Bottom : LIAreaEdge_Top;
            break;
            
        case LIDirection_Down:
            *changeP =  1;
            *areaEdgeP = [self selectionExtendsUp] ? LIAreaEdge_Top : LIAreaEdge_Bottom;
            break;
            
        case LIDirection_Left:
            *changeP = -1;
            *areaEdgeP = [self selectionExtendsRight] ? LIAreaEdge_Right : LIAreaEdge_Left;
            break;

        case LIDirection_Right:
            *changeP =  1;
            *areaEdgeP = [self selectionExtendsLeft] ? LIAreaEdge_Left : LIAreaEdge_Right;
            break;
    }
}

- (LISelectionArea *)areaByResizingInDirection:(LIDirection)direction {
    LIAreaEdge edge;
    NSInteger  change;
    
    [self getSelectionEdge:&edge change:&change forResizeInDirection:direction];

    // attempt to add, or subtract cells within our test area.
    // if the test area contains spanning cells, then we expand
    // the test area until it contains no further unaccounted spanners.
    // we then add or subtract the resulting area and return this new area
    
    BOOL            add;
    LIGridArea      *testArea;

    if (change > 0) {
        switch (edge) {
            case LIAreaEdge_Top:
                add = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.row, 1) columnRange:self.columnRange representedObject:nil];
                break;
                
            case LIAreaEdge_Left:
                add = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:self.rowRange columnRange:NSMakeRange(self.column, 1) representedObject:nil];
                break;
                
            case LIAreaEdge_Right:
                add = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:self.rowRange columnRange:NSMakeRange(self.maxColumn, 1) representedObject:nil];
                break;
                
            case LIAreaEdge_Bottom:
                add = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.maxRow, 1) columnRange:self.columnRange representedObject:nil];
                break;
        }
    } else {
        switch (edge) {
            case LIAreaEdge_Top:
                add = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.row - 1, 1) columnRange:self.columnRange representedObject:nil];
                break;
                
            case LIAreaEdge_Left:
                add = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:self.rowRange columnRange:NSMakeRange(self.column - 1, 1) representedObject:nil];
                break;
                
            case LIAreaEdge_Right:
                add = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:self.rowRange columnRange:NSMakeRange(self.maxColumn - 1, 1) representedObject:nil];
                break;
                
            case LIAreaEdge_Bottom:
                add = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.maxRow - 1, 1) columnRange:self.columnRange representedObject:nil];
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
    
    NSRange newRowRange = self.rowRange;
    NSRange newColumnRange = self.columnRange;
    
    if (add) {
        // adding is straightforward union
        
        newRowRange = NSUnionRange(newRowRange, expandedArea.rowRange);
        newColumnRange = NSUnionRange(newColumnRange, expandedArea.columnRange);
        
    } else {
        // subtracting is a bit trickier:
        
        // We're always subtracting from an edge, so based on the
        // edge we adjust our row or column ranges. In the event that
        // subtraction gives us a range of zero size in any direction
        // then based on the direction, we fix the range to length one
        // at a new location.
        
        switch (edge) {
            case LIAreaEdge_Top:
                newRowRange.location    += expandedArea.rowRange.length;
                newRowRange.length      -= expandedArea.rowRange.length;
                break;
            case LIAreaEdge_Left:
                newColumnRange.location += expandedArea.columnRange.length;
                newColumnRange.length   -= expandedArea.columnRange.length;
                break;
            case LIAreaEdge_Right:
                newColumnRange.length   -= expandedArea.columnRange.length;
                break;
            case LIAreaEdge_Bottom:
                newRowRange.length      -= expandedArea.rowRange.length;
                break;
        }
        
        if (newRowRange.length == 0) {
            if (direction == LIDirection_Up) {
                newRowRange.location -= 1;
                newRowRange.length   += 1;
            } else {
                newRowRange.length   += 1;
            }
        }
        if (newColumnRange.length == 0) {
            if (direction == LIDirection_Right) {
                newColumnRange.location -= 1;
                newColumnRange.length   += 1;
            } else {
                newColumnRange.length   += 1;
            }
        }
    }

    NSUInteger numRows = self.gridControl.numberOfRows;
    NSUInteger numCols = self.gridControl.numberOfColumns;
    
    LISelectionArea *newArea = [[LISelectionArea alloc] initWithGridArea:self.gridArea control:self.gridControl];
    
    if (NSMaxRange(newRowRange) <= numRows && NSMaxRange(newColumnRange) <= numCols) {
        newArea.rowRange = newRowRange;
        newArea.columnRange = newColumnRange;
    } else {
        newArea.rowRange = self.rowRange;
        newArea.columnRange = self.columnRange;
    }
    
    return newArea;
}

@end
