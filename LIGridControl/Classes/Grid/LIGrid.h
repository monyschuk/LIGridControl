//
//  LIGrid.h
//  LIGrid
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"

@class LIGrid, LIGridFieldCell, LIGridDividerCell;

@protocol LIGridDelegate <NSControlTextEditingDelegate>

@optional
- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridFieldCell *)cell forArea:(LIGridArea *)area;

- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forRowDividerAtIndex:(NSUInteger)index;
- (NSCell *)gridControl:(LIGrid *)gridControl willDrawCell:(LIGridDividerCell *)cell forColumnDividerAtIndex:(NSUInteger)index;

- (void)gridControlSelectionDidChange:(NSNotification *)notification;

@end

@protocol LIGridDataSource <NSObject>

- (NSUInteger)gridControlNumberOfRows:(LIGrid *)gridControl;
- (NSUInteger)gridControlNumberOfColumns:(LIGrid *)gridControl;

- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGrid *)gridControl heightOfRowDividerAtIndex:(NSUInteger)index;

- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnAtIndex:(NSUInteger)index;
- (CGFloat)gridControl:(LIGrid *)gridControl widthOfColumnDividerAtIndex:(NSUInteger)index;

- (NSUInteger)gridControlNumberOfFixedAreas:(LIGrid *)gridControl;
- (LIGridArea *)gridControl:(LIGrid *)gridControl fixedAreaAtIndex:(NSUInteger)index;

- (id)gridControl:(LIGrid *)gridControl objectValueForArea:(LIGridArea *)area;
- (void)gridControl:(LIGrid *)gridControl setObjectValue:(id)objectValue forArea:(LIGridArea *)area;

@optional
- (void)gridControl:(LIGrid *)gridControl setHeight:(CGFloat)height   ofRowAtIndex:(NSUInteger)index;
- (void)gridControl:(LIGrid *)gridControl  setWidth:(CGFloat)width ofColumnAtIndex:(NSUInteger)index;

@end

typedef BOOL (^LIGridKeyDownHandlerBlock)(NSEvent *keyEvent);
typedef NSRect (^LIGridScrollRectToVisibleBlock)(NSRect desiredRect);

@interface LIGrid : NSControl

#pragma mark -
#pragma mark Data Source, Delegate

@property(nonatomic, weak) id <LIGridDelegate>   delegate;
@property(nonatomic, weak) id <LIGridDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *dividerColor;
@property(nonatomic, copy) NSColor *backgroundColor;

#pragma mark -
#pragma mark Selection

@property(nonatomic) BOOL showsSelections;
@property(nonatomic, copy) NSArray *selections;

#pragma mark -
#pragma mark Fixed Areas

- (LIGridArea *)areaWithRepresentedObject:(id)object;

#pragma mark -
#pragma mark Editing

- (void)editArea:(LIGridArea *)area;
@property(nonatomic, copy) LIGridKeyDownHandlerBlock keyDownHandler;

#pragma mark -
#pragma mark Cell Sizing

@property(nonatomic) BOOL canResizeRows, canResizeColumns;

#pragma mark -
#pragma mark Layout

- (NSRect)rectForArea:(LIGridArea *)area;

- (NSRect)rectForRowDivider:(NSUInteger)row;
- (NSRect)rectForColumnDivider:(NSUInteger)column;

- (LIGridArea *)areaAtRow:(NSUInteger)row column:(NSUInteger)column;
- (NSArray *)fixedAreasInRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

@property(nonatomic) NSUInteger numberOfRows, numberOfColumns;

- (BOOL)getRow:(NSUInteger *)rowP column:(NSUInteger *)colP atPoint:(NSPoint)point;

#pragma mark -
#pragma mark Animation

- (void)scrollToArea:(LIGridArea *)area animate:(BOOL)shouldAnimate;
@property(nonatomic, copy) LIGridScrollRectToVisibleBlock scrollToVisibleBlock;

#pragma mark -
#pragma mark Drawing

- (void)drawCells:(NSRect)dirtyRect;
- (void)drawDividers:(NSRect)dirtyRect;
- (void)drawBackground:(NSRect)dirtyRect;

@end

@interface NSResponder (LIGridResponderMessages)

- (void)insertFunction:(id)sender;

@end

extern NSString* LIGridControlSelectionDidChangeNotification;

