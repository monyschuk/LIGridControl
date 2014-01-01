//
//  LITableLayout.m
//  Matrix
//
//  Created by Mark Onyschuk on 2013-12-31.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITableLayout.h"

#import "LIGrid.h"
#import "LITable.h"

#import "LIGridField.h"
#import "LIGridDivider.h"

@implementation LITableLayout

- (void)awakeInTable:(LITable *)table {
    if (_table != table) {
        
        self.nextResponder = nil;
        
        _table.grid.delegate = nil;
        _table.rowHeader.delegate = nil;
        _table.columnHeader.delegate = nil;
        
        _table.grid.dataSource = nil;
        _table.rowHeader.dataSource = nil;
        _table.columnHeader.dataSource = nil;

        _table.grid.nextResponder = _table;
        _table.rowHeader.nextResponder = _table;
        _table.columnHeader.nextResponder = _table;
        
        _table = table;
        
        _table.grid.delegate = self;
        _table.rowHeader.delegate = self;
        _table.columnHeader.delegate = self;
        
        _table.grid.dataSource = self;
        _table.rowHeader.dataSource = self;
        _table.columnHeader.dataSource = self;
        
        _table.grid.nextResponder = self;
        _table.rowHeader.nextResponder = self;
        _table.columnHeader.nextResponder = self;
        
        self.nextResponder = _table;

    }
}

- (void)reloadData {
    [self.table.columnHeader reloadData];
    [self.table.rowHeader reloadData];
    [self.table.grid reloadData];
}

- (NSUInteger)gridControlNumberOfRows:(LIGrid *)gridControl {
    return 0;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGrid *)gridControl {
    return 0;
}

- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowAtIndex:(NSUInteger)index {
    return 0;
}
- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowDividerAtIndex:(NSUInteger)index {
    return 0;
}

- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnAtIndex:(NSUInteger)index {
    return 0;
}
- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)index {
    return 0;
}

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGrid *)gridControl {
    return 0;
}
- (LIGridArea *)gridControl:(LIGrid *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return nil;
}

- (id)gridControl:(LIGrid *)gridControl objectValueForArea:(LIGridArea *)area {
    return nil;
}
- (void)gridControl:(LIGrid *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)area {
}

- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area {
    return cell;
}

- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index {
    return cell;
}
- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index {
    return cell;
}

@end
