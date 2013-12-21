//
//  LITableExampleController.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 2013-12-21.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITableExampleController.h"

#import "LITable.h"
#import "LIDocumentView.h"

#import "LIGridField.h"
#import "LIGridDivider.h"

@implementation LITableExampleController

- (void)awakeFromNib {
    [super awakeFromNib];
    

    LIDocumentView *documentView = [[LIDocumentView alloc] initWithFrame:NSMakeRect(0, 0, 5000, 5000)];
    self.scrollView.documentView = documentView;

    self.table = [[LITable alloc] initWithFrame:NSZeroRect];

    [documentView addSubview:self.table];
    [documentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(36)-[_table]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_table)]];
    [documentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(36)-[_table]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_table)]];
    
    [self reloadTable];
}

- (void)reloadTable {
    self.table.rowHeader.delegate = self;
    self.table.columnHeader.delegate = self;
    
    self.table.grid.dataSource = self;
    self.table.rowHeader.dataSource = self;
    self.table.columnHeader.dataSource = self;
    
    [self.table.grid reloadData];
    [self.table.rowHeader reloadData];
    [self.table.columnHeader reloadData];
}

- (NSUInteger)gridControlNumberOfRows:(LIGrid *)gridControl {
    return (gridControl == self.table.columnHeader) ? 1 : 25;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGrid *)gridControl {
    return (gridControl == self.table.rowHeader) ? 1 : 12;
}

- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowAtIndex:(NSUInteger)index {
    return 21;
}
- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowDividerAtIndex:(NSUInteger)index {
    return (gridControl == self.table.columnHeader) ? 0 : 1;
}

- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnAtIndex:(NSUInteger)index {
//    return 72;
    return (gridControl == self.table.rowHeader) ? 32 : 72;
}
- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)index {
    return (gridControl == self.table.rowHeader) ? 0 : 1;
}

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGrid *)gridControl {
    return 0;
}
- (LIGridArea *)gridControl:(LIGrid *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return nil;
}

- (id)gridControl:(LIGrid *)gridControl objectValueForArea:(LIGridArea *)area {
    if (gridControl == self.table.grid) {
        return @(27.25);
    } else if (gridControl == self.table.rowHeader) {
        return @(area.row + 1);
    } else {
        return [NSString stringWithFormat:@"%c", (char)'A' + (char)area.column];
    }
}
- (void)gridControl:(LIGrid *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)area {
}

- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area {
    cell.alignment = NSCenterTextAlignment;
    cell.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    
    return cell;
}

- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index {
    cell.dividerColor = [NSColor colorWithCalibratedWhite:0.975 alpha:1.0];
    return cell;
}
- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index {
    cell.dividerColor = [NSColor colorWithCalibratedWhite:0.975 alpha:1.0];
    return cell;
}

@end
