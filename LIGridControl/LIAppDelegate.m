//
//  LIAppDelegate.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIAppDelegate.h"

#import "LIGridControl.h"

#import "LIGridField.h"
#import "LIGridDivider.h"

@interface LIAppDelegate () <LIGridControlDataSource, LIGridControlDelegate>
@property(nonatomic, weak) IBOutlet LIGridControl *gridControl;
@property(nonatomic, strong) NSMutableDictionary  *gridValues;
@end

@implementation LIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.gridValues = @{}.mutableCopy;
    [self.gridControl setDelegate:self];
    [self.gridControl setDataSource:self];
    
    [self.gridControl reloadData];
}

#pragma mark -
#pragma mark Responder Chain Actions

// this is called by the default key handler
// associated with the grid control, when someone
// starts by typing an '=' sign into a selected cell

- (IBAction)insertFunction:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark LIGridControlDataSource

// lets make this something interesting, like
// 10 billion cells at 100k rows by 100k columns...

// 100,000 by 100,000
- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl {
    return 100000;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl {
    return 100000;
}

// we'll use the control's associated data cell to calculate an appropriate height
// assuming that each cell has the same style; we'd otherwise need to perhaps hold a
// copy of the cell, populate it, then get cell size based on the populated cell

// fixed row heights with zero height dividers
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)anIndex {
    return [gridControl.cell cellSizeForBounds:NSMakeRect(0, 0, 1e6, 1e6)].height;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex {
    return 0;
}

// fixed column width of 72 with alternating column divider widths
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex {
    return 72;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex {
    return (anIndex % 4) ? 0.5 : 2;
}

// we'll display one fixed area that spans several rows and columns
- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl {
    return 1;
}
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return [[LIGridArea alloc] initWithRowRange:NSMakeRange(5, 5) columnRange:NSMakeRange(2, 2) representedObject:@"foo"];
}

// in absence of a value, we'll return something just to show, otherwise we check pockets and return what's stored
- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)coordinate {
    return [self.gridValues objectForKey:coordinate] ? [self.gridValues objectForKey:coordinate] : @(127.5);
}
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)coordinate {
    [self.gridValues setObject:objectValue forKey:coordinate];
}

// we set wrapping and background color of the cell based on the area...
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area {
    BOOL wraps = (area.rowRange.length > 1);
    
    [cell setWraps:wraps];
    [cell setScrollable:!wraps];
    [cell setLineBreakMode:!wraps ? NSLineBreakByTruncatingTail : NSLineBreakByWordWrapping];

    if (area.representedObject) {
        [cell setBackgroundColor:[[NSColor redColor] blendedColorWithFraction:0.90 ofColor:[NSColor whiteColor]]];
    } else {
        [cell setBackgroundColor:[NSColor controlAlternatingRowBackgroundColors][area.row % 2]];
    }
    return cell;
}

// we don't do anything special with our row and column dividers, beyond set column divider colors to black...
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index {
    return cell;
}
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index {
    cell.dividerColor = [NSColor blackColor];
    return cell;
}

@end
