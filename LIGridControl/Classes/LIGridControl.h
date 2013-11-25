//
//  LIGridControl.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"

@class LIGridControl;
@protocol LIGridControlDataSource <NSObject>

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl;
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl;

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)index;

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)index;

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl;
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index;

- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)coordinate;
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)coordinate;

@end

@interface LIGridControl : NSView

#pragma mark -
#pragma mark Data Source

@property(nonatomic, weak) id <LIGridControlDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic, copy) NSColor *backgroundColor;

#pragma mark -
#pragma mark Layout

- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column;
- (NSRect)rectForRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

#pragma mark -
#pragma mark Drawing

- (void)removeAllSubviews;
- (void)updateSubviewsInRect:(NSRect)dirtyRect;

@end

