//
//  LIAppDelegate.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIAppDelegate.h"

#import "LIGridControl.h"
#import "LIGridCellView.h"

@interface LIAppDelegate () <LIGridControlDataSource>
@property(nonatomic, weak) IBOutlet LIGridControl *gridControl;
@property(nonatomic, strong) NSMutableDictionary *gridValues;
@end

@implementation LIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.gridValues = @{}.mutableCopy;
    [self.gridControl setDataSource:self];
}

#pragma mark -
#pragma mark LIGridControlDataSource

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl {
    return 4000;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl {
    return 8000;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)anIndex {
    return 18;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex {
    return 0.5;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex {
    return 72;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex {
    return (anIndex % 5) ? 0.5 : 1.5;
}

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl {
    return 1;
}
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return [LIGridArea areaWithRowRange:NSMakeRange(0, 10) columnRange:NSMakeRange(0, 1) representedObject:@"foo"];
}

- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)coordinate {
    return [self.gridValues objectForKey:coordinate];
}
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)coordinate {
    [self.gridValues setObject:objectValue forKey:coordinate];
}

- (void)gridControl:(LIGridControl *)gridControl willDisplayCellView:(LIGridCellView *)cellView forArea:(LIGridArea *)area {
    [cellView setBackgroundColor:[NSColor controlAlternatingRowBackgroundColors][area.row % 2]];
}

@end
