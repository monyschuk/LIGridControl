//
//  LIAppDelegate.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIAppDelegate.h"

#import "LIGridControl.h"

@interface LIAppDelegate () <LIGridControlDataSource>
@property(nonatomic, weak) IBOutlet LIGridControl *gridControl;
@end

@implementation LIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.gridControl setDataSource:self];
}

#pragma mark -
#pragma mark LIGridControlDataSource

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl {
    return 100;
}
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl {
    return 100;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)anIndex {
    return 21;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex {
    return 1;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex {
    return 72;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex {
    return 1;
}

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl {
    return 1;
}
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index {
    return [LIGridArea areaWithRowRange:NSMakeRange(0, 10) columnRange:NSMakeRange(0, 1) representedObject:@"foo"];
}

- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)coordinate {
    return coordinate.representedObject;
}
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)coordinate {
    
}

@end
