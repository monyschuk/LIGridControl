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

- (void)awakeInTableView:(LITable *)tableView {
    if (_tableView != tableView) {
        
        self.nextResponder = nil;
        
        _tableView.grid.delegate = nil;
        _tableView.rowHeader.delegate = nil;
        _tableView.columnHeader.delegate = nil;
        
        _tableView.grid.dataSource = nil;
        _tableView.rowHeader.dataSource = nil;
        _tableView.columnHeader.dataSource = nil;

        _tableView.grid.nextResponder = _tableView;
        _tableView.rowHeader.nextResponder = _tableView;
        _tableView.columnHeader.nextResponder = _tableView;
        
        _tableView = tableView;
        
        _tableView.grid.delegate = self;
        _tableView.rowHeader.delegate = self;
        _tableView.columnHeader.delegate = self;
        
        _tableView.grid.dataSource = self;
        _tableView.rowHeader.dataSource = self;
        _tableView.columnHeader.dataSource = self;
        
        _tableView.grid.nextResponder = self;
        _tableView.rowHeader.nextResponder = self;
        _tableView.columnHeader.nextResponder = self;
        
        self.nextResponder = _tableView;
    }
}

- (void)dealloc {
    _tableView.grid.delegate = nil;
    _tableView.rowHeader.delegate = nil;
    _tableView.columnHeader.delegate = nil;
    
    _tableView.grid.dataSource = nil;
    _tableView.rowHeader.dataSource = nil;
    _tableView.columnHeader.dataSource = nil;
    
    _tableView.grid.nextResponder = _tableView;
    _tableView.rowHeader.nextResponder = _tableView;
    _tableView.columnHeader.nextResponder = _tableView;
}

- (void)reloadData {
    [self.tableView.columnHeader reloadData];
    [self.tableView.rowHeader reloadData];
    [self.tableView.grid reloadData];
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
