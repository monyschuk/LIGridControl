//
//  LIGridSelection.m
//  LIGrid
//
//  Created by Mark Onyschuk on 12/11/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridSelection.h"

#import "LIGridArea.h"
#import "LIGrid.h"

@interface LIGridSelection()
@property(readwrite, nonatomic, copy) LIGridArea *gridArea;
@property(readwrite, nonatomic, strong) LIGridArea *initialArea;

@end

@implementation LIGridSelection

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column gridControl:(LIGrid *)gridControl {
    if ((self = [super init])) {
        _row = row;
        _column = column;
        _gridControl = gridControl;
        
        _initialArea = [gridControl areaAtRow:row column:column];
        _gridArea    = [_initialArea copy];
    }
    return self;
}

#pragma mark -
#pragma mark Editing

- (LIGridArea *)editingArea {
    return [_gridArea isEqual:_initialArea] ? _initialArea : nil;
}

#pragma mark -
#pragma mark Area Movement

- (LIGridSelection *)selectionByMovingInDirection:(LIDirection)direction {
    NSInteger dRows = 0, dCols = 0;
    NSInteger nextRow = self.row, nextCol = self.column;

    switch (direction) {
        case LIDirection_Up:
            dRows = -1;
            break;
        case LIDirection_Down:
            dRows = 1;
            break;
        case LIDirection_Left:
            dCols = -1;
            break;
        case LIDirection_Right:
            dCols = 1;
            break;
    }
    
    nextRow += dRows;
    nextCol += dCols;
    
    while ((nextRow >= 0)
           && (nextCol >= 0)
           && (nextRow < self.gridControl.numberOfRows)
           && (nextCol < self.gridControl.numberOfColumns)) {

        LIGridArea *nextArea = [self.gridControl areaAtRow:nextRow column:nextCol];
        if (! [self.gridArea isEqual:nextArea]) {
            return [[LIGridSelection alloc] initWithRow:nextRow column:nextCol gridControl:self.gridControl];
        }

        nextRow += dRows;
        nextCol += dCols;
    }
    
    return self;
}

#pragma mark -
#pragma mark Area Sizing

typedef enum {
    LISelectionEdge_Top,
    LISelectionEdge_Left,
    LISelectionEdge_Right,
    LISelectionEdge_Bottom
} LISelectionEdge;

- (BOOL)selectionExtendsUp {
    return (self.initialArea.row > self.gridArea.row);
}
- (BOOL)selectionExtendsDown {
    return (self.initialArea.maxRow < self.gridArea.maxRow);
}
- (BOOL)selectionExtendsLeft {
    return (self.initialArea.column > self.gridArea.column);
}
- (BOOL)selectionExtendsRight {
    return (self.initialArea.maxColumn < self.gridArea.maxColumn);
}

- (void)getSelectionEdge:(LISelectionEdge *)areaEdgeP change:(NSInteger *)changeP forResizeInDirection:(LIDirection)direction {
    switch (direction) {
        case LIDirection_Up:
            *changeP = -1;
            *areaEdgeP = [self selectionExtendsDown] ? LISelectionEdge_Bottom : LISelectionEdge_Top;
            break;
            
        case LIDirection_Down:
            *changeP =  1;
            *areaEdgeP = [self selectionExtendsUp] ? LISelectionEdge_Top : LISelectionEdge_Bottom;
            break;
            
        case LIDirection_Left:
            *changeP = -1;
            *areaEdgeP = [self selectionExtendsRight] ? LISelectionEdge_Right : LISelectionEdge_Left;
            break;
            
        case LIDirection_Right:
            *changeP =  1;
            *areaEdgeP = [self selectionExtendsLeft] ? LISelectionEdge_Left : LISelectionEdge_Right;
            break;
    }
}

- (LIGridSelection *)selectionByResizingInDirection:(LIDirection)direction {
    NSInteger change;
    LISelectionEdge edge;
    
    [self getSelectionEdge:&edge change:&change forResizeInDirection:direction];
    
    // attempt to add, or subtract cells within our test area.
    // if the test area contains spanning cells, then we expand
    // the test area until it contains no further unaccounted spanners.
    // we then add or subtract the resulting area and return this new area
    
    BOOL additive;
    LIGridArea *testArea;
    
    if (change > 0) {
        switch (edge) {
            case LISelectionEdge_Top:
                additive = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.gridArea.row, 1) columnRange:self.gridArea.columnRange representedObject:nil];
                break;
                
            case LISelectionEdge_Left:
                additive = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:self.gridArea.rowRange columnRange:NSMakeRange(self.gridArea.column, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Right:
                additive = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:self.gridArea.rowRange columnRange:NSMakeRange(self.gridArea.maxColumn, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Bottom:
                additive = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.gridArea.maxRow, 1) columnRange:self.gridArea.columnRange representedObject:nil];
                break;
        }
    } else {
        switch (edge) {
            case LISelectionEdge_Top:
                additive = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.gridArea.row - 1, 1) columnRange:self.gridArea.columnRange representedObject:nil];
                break;
                
            case LISelectionEdge_Left:
                additive = YES;
                testArea = [[LIGridArea alloc] initWithRowRange:self.gridArea.rowRange columnRange:NSMakeRange(self.gridArea.column - 1, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Right:
                additive = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:self.gridArea.rowRange columnRange:NSMakeRange(self.gridArea.maxColumn - 1, 1) representedObject:nil];
                break;
                
            case LISelectionEdge_Bottom:
                additive = NO;
                testArea = [[LIGridArea alloc] initWithRowRange:NSMakeRange(self.gridArea.maxRow - 1, 1) columnRange:self.gridArea.columnRange representedObject:nil];
                break;
        }
    }
    
    LIGridArea  *expandedArea = nil;
    
    while (![testArea isEqual:expandedArea]) {
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
    
    NSRange newRowRange = self.gridArea.rowRange;
    NSRange newColumnRange = self.gridArea.columnRange;
    
    if (additive) {
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
            case LISelectionEdge_Top:
                newRowRange.location    += expandedArea.rowRange.length;
                newRowRange.length      -= expandedArea.rowRange.length;
                break;
            case LISelectionEdge_Left:
                newColumnRange.location += expandedArea.columnRange.length;
                newColumnRange.length   -= expandedArea.columnRange.length;
                break;
            case LISelectionEdge_Right:
                newColumnRange.length   -= expandedArea.columnRange.length;
                break;
            case LISelectionEdge_Bottom:
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
    
    if (NSMaxRange(newRowRange) > numRows || NSMaxRange(newColumnRange) > numCols) {
        newRowRange = self.gridArea.rowRange;
        newColumnRange = self.gridArea.columnRange;
    }

    LIGridSelection *newSelection = [[LIGridSelection alloc] initWithRow:self.row column:self.column gridControl:self.gridControl];
    newSelection.gridArea = [[LIGridArea alloc] initWithRowRange:newRowRange columnRange:newColumnRange representedObject:nil];
    return newSelection;
}

@end
