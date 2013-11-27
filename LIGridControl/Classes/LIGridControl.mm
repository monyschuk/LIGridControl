//
//  LIGridControl.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridControl.h"

#import "LIGridArea.h"
#import "LIGridField.h"
#import "LIGridDivider.h"

#define DF_DIVIDER_COLOR    [NSColor gridColor]
#define DF_BACKGROUND_COLOR [NSColor whiteColor]

// LIGridControl allows users to specify row, column, row divider, and column divider sizing.
// To do this, the class stores row and column size information as vectors of row and column spans.
// These vectors of spans are organized in order. Row spans, for example, are organized like so:
//
//      [DIV 0][ROW 0], [DIV 1][ROW 1], ...[DIV N][ROW N][DIV N+1]
//
// That's to say, a grid with 100 rows stores 201 row spans. In general. A grid with N x M rows and columns
// will store 2N+1 x 2M+1 spans.
//
// Note that if you're going to introduce a bug in display, an area ripe for confusion is this concept of grid
// and span space. Make sure that you understand which space you're dealing with. Typically for the outside world
// we express coordinates in grid space. the helper class LIGridArea expresses space in grid space. When working
// internally, we typically work in span space. The helper C++ class GridArea expresses space in span space and
// provides conversion operators that allow you to convert between the two representations.


//
//
// UTILITIES
//
//


#include "LIGridUtil.h"

using namespace LIGrid::Util;


//
//
// IMPLEMENTATION
//
//

@interface LIGridControl() {
    GridAreaMap  _fixedAreaMap;
    GridAreaList _fixedAreaList;
    
    GridSpanList _rowSpans, _columnSpans;
}

@property(nonatomic, strong) LIGridArea *editingArea;
@property(nonatomic, strong) NSCell     *editingCell; // cell class may be replaced by the data source

@end

@implementation LIGridControl

+ (Class)cellClass {
    return [LIGridFieldCell class];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureGridControl];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureGridControl];
}

- (void)dealloc {
}

- (void)configureGridControl {
    _dividerColor       = DF_DIVIDER_COLOR;
    _backgroundColor    = DF_BACKGROUND_COLOR;
    
    self.cell = [[LIGridFieldCell alloc] initTextCell:@""];

    
    // default key event handling block
    __weak LIGridControl *weakSelf  = self;
    _keyDownHandler                 = ^BOOL(NSEvent *keyEvent) {
        if ([keyEvent.characters isEqualToString:@"="]) {
            [weakSelf doCommandBySelector:@selector(insertFunction:)];
            return YES;
            
        } else {
            NSMutableCharacterSet *editChars = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
            [editChars formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
            
            if (weakSelf.selectedArea != nil) {
                if ([[keyEvent characters] rangeOfCharacterFromSet:editChars].location != NSNotFound) {
                    [weakSelf editArea:weakSelf.selectedArea];
                    [weakSelf.currentEditor insertText:keyEvent.characters];
                    
                    return YES;
                }
            }
        }
        return NO;
    };

    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
}


#pragma mark -
#pragma mark Data Source

- (void)setDataSource:(id<LIGridControlDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self reloadData];
    }
}

- (void)reloadData {
    NSUInteger rowCount = [self.dataSource gridControlNumberOfRows:self];
    NSUInteger columnCount = [self.dataSource gridControlNumberOfColumns:self];
    NSUInteger fixedAreaCount = [self.dataSource gridControlNumberOfFixedAreas:self];

    _fixedAreaMap.clear();
    _fixedAreaList.resize(fixedAreaCount);
    
    _rowSpans.resize(rowCount * 2 + 1);
    _columnSpans.resize(columnCount * 2 + 1);

    // reload row spans...

    NSUInteger i;
    CGFloat offset = 0;
    
    for (i = 0; i < rowCount; i++) {
        _rowSpans[2*i].start        = offset;
        _rowSpans[2*i].length       = [self.dataSource gridControl:self heightOfRowDividerAtIndex:i];
        
        offset += _rowSpans[2*i].length;
        
        _rowSpans[2*i+1].start      = offset;
        _rowSpans[2*i+1].length     = [self.dataSource gridControl:self heightOfRowAtIndex:i];
        
        offset += _rowSpans[2*i+1].length;
    }
    
    _rowSpans[2*i].start            = offset;
    _rowSpans[2*i].length           = [self.dataSource gridControl:self heightOfRowDividerAtIndex:i];
    
    // reload column spans...
    
    offset = 0;

    for (i = 0; i < columnCount; i++) {
        _columnSpans[2*i].start     = offset;
        _columnSpans[2*i].length    = [self.dataSource gridControl:self widthOfColumnDividerAtIndex:i];
        
        offset += _columnSpans[2*i].length;
        
        _columnSpans[2*i+1].start   = offset;
        _columnSpans[2*i+1].length  = [self.dataSource gridControl:self widthOfColumnAtIndex:i];
        
        offset += _columnSpans[2*i+1].length;
    }
    
    _columnSpans[2*i].start         = offset;
    _columnSpans[2*i].length        = [self.dataSource gridControl:self widthOfColumnDividerAtIndex:i];
    
    // reload spanning areas...
    
    for (i = 0; i < fixedAreaCount; i++) {
        LIGridArea *coord = [self.dataSource gridControl:self fixedAreaAtIndex:i];

        _fixedAreaList[i] = coord;
        _fixedAreaMap[coord] = coord.representedObject;
    }
    
    [self invalidateIntrinsicContentSize];
}


#pragma mark -
#pragma mark Display Properties

- (void)setDividerColor:(NSColor *)dividerColor {
    if (_dividerColor != dividerColor) {
        _dividerColor = dividerColor.copy;
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor.copy;
        
        [self setNeedsDisplay:YES];
    }
}


#pragma mark -
#pragma mark Events

- (BOOL)becomeFirstResponder {
    return YES;
}
- (BOOL)resignFirstResponder {
    return YES;
}
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint location = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    LIGridArea *gridArea = [self areaAtPoint:location];
    if (gridArea) [self editArea:gridArea];
}

- (void)keyDown:(NSEvent *)theEvent {
    if (self.keyDownHandler == nil || self.keyDownHandler(theEvent) == NO) {
        [self interpretKeyEvents:@[theEvent]];
    }
}

#pragma mark -
#pragma mark Editing

- (void)editArea:(LIGridArea *)area {
    NSCell *editingCell = [self.cell copy];
    
    // end existing editing, if any...
    [self.window makeFirstResponder:self];
    
    [editingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:area]];
    editingCell = [self.dataSource gridControl:self willDrawCell:(id)editingCell forArea:area];
    
    if (editingCell.isEditable || editingCell.isSelectable) {
        
        self.editingArea = area;
        self.editingCell = editingCell;
        
        
        NSRect frame   = [self rectForArea:area];
        NSText *editor = [editingCell setUpFieldEditorAttributes:[self.window fieldEditor:YES forObject:self]];
        
        [editingCell selectWithFrame:frame inView:self editor:editor delegate:self start:0 length:_editingCell.stringValue.length];
    }
}


#pragma mark -
#pragma mark Layout

- (NSSize)intrinsicContentSize {
    const GridSpan lastRow = _rowSpans.size() ? _rowSpans.back() : GridSpan();
    const GridSpan lastCol = _columnSpans.size() ? _columnSpans.back() : GridSpan();
    
    return NSMakeSize(lastCol.end(), lastRow.end());
}

- (NSRect)rectForRowDivider:(NSUInteger)row {
    GridSpanListRange rowSpanRange(row * 2, 1);
    GridSpanListRange columnSpanRange(0, _columnSpans.size());
    
    return RectWithGridSpanListRanges(rowSpanRange, columnSpanRange, _rowSpans, _columnSpans);
}
- (NSRect)rectForColumnDivider:(NSUInteger)column {
    GridSpanListRange rowSpanRange(0, _rowSpans.size());
    GridSpanListRange columnSpanRange(column * 2, 1);
    
    return RectWithGridSpanListRanges(rowSpanRange, columnSpanRange, _rowSpans, _columnSpans);
}

- (NSRect)rectForArea:(LIGridArea *)area {
    GridArea gridArea = area;
    return RectWithGridSpanListRanges(gridArea.rowSpanRange, gridArea.columnSpanRange, _rowSpans, _columnSpans);
}

- (LIGridArea *)areaAtPoint:(NSPoint)point {
    NSUInteger rowIndex = IndexOfSpanWithLocation(_rowSpans, point.y);
    NSUInteger colIndex = IndexOfSpanWithLocation(_columnSpans, point.x);
    
    if (rowIndex != NSNotFound && colIndex != NSNotFound) {
        if (IS_CELL_INDEX(rowIndex) && IS_CELL_INDEX(colIndex)) {
            GridArea hitArea(rowIndex, colIndex);
            
            for (auto it = _fixedAreaList.begin(); it != _fixedAreaList.end(); it++) {
                if (hitArea.intersects(*it)) {
                    LIGridArea *area = *it;
                    area.representedObject = _fixedAreaMap.find(*it)->second;
                    
                    return area;
                }
            }
            return hitArea;
        }
    }
    return nil;
}


#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawBackground:dirtyRect];
    [self drawDividers:dirtyRect];
    [self drawCells:dirtyRect];
}

- (void)drawCells:(NSRect)dirtyRect {
    LIGridFieldCell *drawingCell = [self.cell copy];
    LIGridArea      *drawingArea = [[LIGridArea alloc] init];
    
    GridSpanListRange rowSpanRange, colSpanRange;
    GetGridSpanListRangesWithRect(rowSpanRange, colSpanRange, _rowSpans, _columnSpans, dirtyRect);
    
    for (NSUInteger r = IS_CELL_INDEX(rowSpanRange.start) ? rowSpanRange.start : rowSpanRange.start + 1, maxr = rowSpanRange.end(); r <= maxr; r += 2) {
        for (NSUInteger c = IS_CELL_INDEX(colSpanRange.start) ? colSpanRange.start : colSpanRange.start + 1, maxc = colSpanRange.end(); c <= maxc; c += 2) {
            NSRect rect = NSMakeRect(_columnSpans[c].start, _rowSpans[r].start, _columnSpans[c].length, _rowSpans[r].length);

            drawingArea.row = r/2;
            drawingArea.column = c/2;
            drawingArea.representedObject = nil;
            
            BOOL isFixed = NO;
            GridArea area = drawingArea;
            for (auto it = _fixedAreaList.begin(); it != _fixedAreaList.end(); it++) {
                if (area.intersects(*it)) {
                    isFixed = YES;
                    break;
                }
            }
            
            if (!isFixed) {
                [drawingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:drawingArea]];
                [[self.dataSource gridControl:self willDrawCell:drawingCell forArea:drawingArea] drawWithFrame:rect inView:nil];
            }
        }
    }
    
    GridArea visibleArea(rowSpanRange, colSpanRange);
    
    for (auto it = _fixedAreaMap.begin(); it != _fixedAreaMap.end(); it++) {
        if (it->first.intersects(visibleArea)) {
            LIGridArea *fixedArea = it->first;
            fixedArea.representedObject = it->second;
            
            NSRect rect = RectWithGridSpanListRanges(it->first.rowSpanRange, it->first.columnSpanRange, _rowSpans, _columnSpans);
            
            [drawingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:fixedArea]];
            [[self.dataSource gridControl:self willDrawCell:drawingCell forArea:fixedArea] drawWithFrame:rect inView:nil];
        }
    }
}

- (void)drawDividers:(NSRect)dirtyRect {
    LIGridDividerCell *dividerCell = [[LIGridDividerCell alloc] initTextCell:@""];
    
    GridSpanListRange rowSpanRange, colSpanRange;
    GetGridSpanListRangesWithRect(rowSpanRange, colSpanRange, _rowSpans, _columnSpans, dirtyRect);
    
    for (NSUInteger r = IS_DIVIDER_INDEX(rowSpanRange.start) ? rowSpanRange.start : rowSpanRange.start + 1, maxr = rowSpanRange.end(); r <= maxr; r += 2) {
        NSRect rect = NSMakeRect(NSMinX(dirtyRect), _rowSpans[r].start, NSWidth(dirtyRect), _rowSpans[r].length);
        
        if (!NSIsEmptyRect(rect)) {
            dividerCell.dividerColor = self.dividerColor;
            [[self.dataSource gridControl:self willDrawCell:dividerCell forRowDividerAtIndex:r/2] drawWithFrame:rect inView:nil];
        }
    }
    for (NSUInteger c = IS_DIVIDER_INDEX(colSpanRange.start) ? colSpanRange.start : colSpanRange.start + 1, maxc = colSpanRange.end(); c <= maxc; c += 2) {
        NSRect rect = NSMakeRect(_columnSpans[c].start, NSMinY(dirtyRect), _columnSpans[c].length, NSHeight(dirtyRect));
        
        if (!NSIsEmptyRect(rect)) {
            dividerCell.dividerColor = self.dividerColor;
            [[self.dataSource gridControl:self willDrawCell:dividerCell forColumnDividerAtIndex:c/2] drawWithFrame:rect inView:nil];
        }
    }
}

- (void)drawBackground:(NSRect)dirtyRect {
    NSInteger rectCount;
    const NSRect *rectList;
    [self getRectsBeingDrawn:&rectList count:&rectCount];
    
    [self.backgroundColor set];
    NSRectFillList(rectList, rectCount);
}

- (void)viewWillStartLiveResize {
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
    
}
- (void)viewDidEndLiveResize {
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
}

@end

