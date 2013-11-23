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
    return 23;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex {
    return 0.25;
}

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex {
    return 72;
}
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex {
    return 0.25;
}

@end
