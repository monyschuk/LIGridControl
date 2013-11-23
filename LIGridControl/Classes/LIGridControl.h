//
//  LIGridControl.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LIGridControl;
@protocol LIGridControlDataSource <NSObject>

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl;
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl;

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)anIndex;
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)anIndex;

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)anIndex;
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)anIndex;

@end

@interface LIGridControl : NSControl

#pragma mark -
#pragma mark Data Source

@property(nonatomic, weak) id <LIGridControlDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic, copy) NSColor *backgroundColor;

#pragma mark -
#pragma mark Drawing

- (void)drawBackground:(const NSRect *)rectArray count:(NSInteger)rectCount;
- (void)drawDividers:(const NSRect *)rectArray count:(NSInteger)rectCount;
- (void)drawCells:(const NSRect *)rectArray count:(NSInteger)rectCount;

@end
