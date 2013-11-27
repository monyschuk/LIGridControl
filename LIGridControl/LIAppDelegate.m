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

@interface LIAppDelegate () <LIGridControlDataSource>
@property(nonatomic, weak) IBOutlet LIGridControl *gridControl;
@property(nonatomic, strong) NSMutableDictionary  *gridValues;
@end

@implementation LIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.gridValues = @{}.mutableCopy;
    [self.gridControl setDataSource:self];
}

#pragma mark -
#pragma mark Responder Chain Actions

- (IBAction)insertFunction:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark LIGridControlDataSource

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl {
    return 100000;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl {
    return 10000;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)anIndex {
    return 21;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex {
    return 0;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex {
    return 72;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex {
    return (anIndex % 4) ? 0.5 : 4;
}

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl {
    return 1;
}
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return [LIGridArea areaWithRowRange:NSMakeRange(1, 10) columnRange:NSMakeRange(0, 1) representedObject:@"foo"];
}

- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)coordinate {
    return [self.gridValues objectForKey:coordinate] ? [self.gridValues objectForKey:coordinate] : @(127.5);
}
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)coordinate {
    [self.gridValues setObject:objectValue forKey:coordinate];
}

- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area {
    if (area.representedObject) {
        [cell setBackgroundColor:[[NSColor redColor] blendedColorWithFraction:0.90 ofColor:[NSColor whiteColor]]];
    } else {
        [cell setBackgroundColor:[NSColor controlAlternatingRowBackgroundColors][area.row % 2]];
    }
    return cell;
}

- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index {
    return cell;
}
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index {
    cell.dividerColor = (index % 2) ? [NSColor gridColor] : [NSColor blackColor];
    return cell;
}

@end
