//
//  LIGridControl.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"

@class LIGridControl, LIGridFieldCell, LIGridDividerCell;

@protocol LIGridControlDelegate <NSControlTextEditingDelegate>

@optional
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area;

- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index;
- (NSCell *)gridControl:(LIGridControl *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index;

@end

@protocol LIGridControlDataSource <NSObject>

- (NSUInteger)gridControlNumberOfRows:(LIGridControl *)gridControl;
- (NSUInteger)gridControlNumberOfColumns:(LIGridControl *)gridControl;

- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGridControl *)gridControl heightOfRowDividerAtIndex:(NSUInteger)index;

- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGridControl *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)index;

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGridControl *)gridControl;
- (LIGridArea *)gridControl:(LIGridControl *)gridControl fixedAreaAtIndex:(NSUInteger)index;

- (id)gridControl:(LIGridControl *)gridControl objectValueForArea:(LIGridArea *)area;
- (void)gridControl:(LIGridControl *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)area;

@end

typedef BOOL (^LIGridControlKeyDownHandlerBlock)(NSEvent *keyEvent);

@interface LIGridControl : NSControl

#pragma mark -
#pragma mark Data Source, Delegate

@property(nonatomic, weak) id <LIGridControlDelegate> delegate;
@property(nonatomic, weak) id <LIGridControlDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic, copy) NSColor *backgroundColor;

#pragma mark -
#pragma mark Selection

@property(nonatomic, weak) LIGridArea *selectedArea;
@property(nonatomic, copy) NSIndexSet *selectedRowIndexes, *selectedColumnIndexes;

#pragma mark -
#pragma mark Editing

- (void)editArea:(LIGridArea *)area;
@property(nonatomic, copy) LIGridControlKeyDownHandlerBlock keyDownHandler;

#pragma mark -
#pragma mark Layout

- (NSRect)rectForRowDivider:(NSUInteger)row;
- (NSRect)rectForColumnDivider:(NSUInteger)column;

- (NSRect)rectForArea:(LIGridArea *)area;

#pragma mark -
#pragma mark Drawing

- (void)drawCells:(NSRect)dirtyRect;
- (void)drawDividers:(NSRect)dirtyRect;
- (void)drawBackground:(NSRect)dirtyRect;

@end

@interface NSResponder (LIGridControlResponderMessages)

- (void)insertFunction:(id)sender;

@end