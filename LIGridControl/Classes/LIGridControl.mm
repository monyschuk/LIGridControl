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
    
    BOOL _delegateWillDrawCellForArea;
    BOOL _delegateWillDrawCellForRowDivider;
    BOOL _delegateWillDrawCellForColumnDivider;
}

// properties used during editing
@property(nonatomic, strong) LIGridArea *editingArea;
@property(nonatomic, strong) NSCell     *editingCell;

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
    
    _showsSelection     = YES;
    _selectedAreas      = @[];
    
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
            
            NSArray *selectedAreas = weakSelf.selectedAreas;
            
            if (selectedAreas.count == 1) {
                if ([[keyEvent characters] rangeOfCharacterFromSet:editChars].location != NSNotFound) {
                    [weakSelf editArea:selectedAreas.lastObject];
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
#pragma mark Delegate & Data Source

- (void)setDelegate:(id<LIGridControlDelegate>)delegate {
    if (_delegate != delegate) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
 
        if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
            [nc removeObserver:_delegate name:NSControlTextDidBeginEditingNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
            [nc removeObserver:_delegate name:NSControlTextDidChangeNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
            [nc removeObserver:_delegate name:NSControlTextDidEndEditingNotification object:self];

        _delegate = delegate;
        
        if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
            [nc addObserver:_delegate selector:@selector(controlTextDidChange:) name:NSControlTextDidBeginEditingNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
            [nc addObserver:_delegate selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
            [nc addObserver:_delegate selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:self];

        
        _delegateWillDrawCellForArea = [_delegate respondsToSelector:@selector(gridControl:willDrawCell:forArea:)];
        _delegateWillDrawCellForRowDivider = [_delegate respondsToSelector:@selector(gridControl:willDrawCell:forRowDividerAtIndex:)];
        _delegateWillDrawCellForColumnDivider = [_delegate respondsToSelector:@selector(gridControl:willDrawCell:forColumnDividerAtIndex:)];
    }
}
- (void)setDataSource:(id<LIGridControlDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
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
#pragma mark Selection

- (void)setShowsSelection:(BOOL)showsSelection {
    if (_showsSelection != showsSelection) {
        _showsSelection = showsSelection;
        
        if (self.selectedAreas.count) {
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)setSelectedAreas:(NSArray *)selectedAreas {
    if (_selectedAreas != selectedAreas) {
        // redraw old selection
        for (LIGridArea *area in _selectedAreas) [self setNeedsDisplayInRect:[self rectForArea:area]];

        _selectedAreas = [selectedAreas copy];
        
        // draw new selection...
        for (LIGridArea *area in _selectedAreas) [self setNeedsDisplayInRect:[self rectForArea:area]];
    }
}

#pragma mark -
#pragma mark Event Handling

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
    
    NSUInteger row, col;
    if ([self getRow:&row column:&col atPoint:location]) {
        
        LISelectionArea *selection      = [[LISelectionArea alloc] initWithGridArea:[[LIGridArea alloc] initWithRow:row column:col representedObject:nil] control:self];
        NSMutableArray  *selectedAreas  = [[NSMutableArray alloc] initWithArray:self.selectedAreas];

        [self scrollToArea:selection.gridArea animate:YES];
        
        if ([selectedAreas containsObject:selection]) {
            [self editArea:selection.gridArea];
            
        } else {
            if (theEvent.modifierFlags & NSShiftKeyMask) {
                [selectedAreas addObject:selection];
                
            } else {
                [selectedAreas setArray:@[selection]];
            }
            
            self.selectedAreas = selectedAreas;
        }
    }
}


#pragma mark -
#pragma mark Key Event Handling

- (void)keyDown:(NSEvent *)theEvent {
    if (self.keyDownHandler == nil || self.keyDownHandler(theEvent) == NO) {
        [self interpretKeyEvents:@[theEvent]];
    }
}

- (void)insertTab:(id)sender {
    
}
- (void)insertBacktab:(id)sender {
    
}
- (void)insertNewline:(id)sender {
    
}

- (void)moveInDirection:(LIDirection)direction extendSelection:(BOOL)extendSelection {
    LISelectionArea *currentArea  = self.selectedAreas.lastObject;
    
    if (currentArea != nil) {
        LISelectionArea *nextSelectedArea = [currentArea areaByResizingInDirection:direction];
        NSMutableArray  *newSelectedAreas = [[NSMutableArray alloc] initWithArray:self.selectedAreas];
        
        if (extendSelection) {
            [newSelectedAreas removeLastObject];
            [newSelectedAreas addObject:[currentArea areaByResizingInDirection:direction]];
        } else {
            [newSelectedAreas removeAllObjects];
            [newSelectedAreas addObject:[currentArea areaByMovingInDirection:direction]];
        }
        
        self.selectedAreas = newSelectedAreas;
        
        [self scrollToArea:nextSelectedArea animate:YES];
    }
}

- (void)moveUp:(id)sender {
    [self moveInDirection:LIDirection_Up extendSelection:NO];
}
- (void)moveDown:(id)sender {
    [self moveInDirection:LIDirection_Down extendSelection:NO];
}
- (void)moveLeft:(id)sender {
    [self moveInDirection:LIDirection_Left extendSelection:NO];
}
- (void)moveRight:(id)sender {
    [self moveInDirection:LIDirection_Right extendSelection:NO];
}

- (void)moveUpAndModifySelection:(id)sender {
    [self moveInDirection:LIDirection_Up extendSelection:YES];
}
- (void)moveDownAndModifySelection:(id)sender {
    [self moveInDirection:LIDirection_Down extendSelection:YES];
}
- (void)moveLeftAndModifySelection:(id)sender {
    [self moveInDirection:LIDirection_Left extendSelection:YES];
}
- (void)moveRightAndModifySelection:(id)sender {
    [self moveInDirection:LIDirection_Right extendSelection:YES];
}


#pragma mark -
#pragma mark Editing

- (void)editArea:(LIGridArea *)area {
    NSCell *editingCell = [self.cell copy];
    
    // end existing editing, if any...
    [self.window makeFirstResponder:self];
    
    [editingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:area]];
    editingCell = (_delegateWillDrawCellForArea) ? [self.delegate gridControl:self willDrawCell:(id)editingCell forArea:area] : editingCell;
    
    if (editingCell.isEditable || editingCell.isSelectable) {
        self.selectedAreas = @[area];
        [self scrollToArea:area animate:NO];
        
        self.editingArea = area;
        self.editingCell = editingCell;
        
        NSRect frame   = [self rectForArea:area];
        NSText *editor = [editingCell setUpFieldEditorAttributes:[self.window fieldEditor:YES forObject:self]];

        [editingCell selectWithFrame:frame inView:self editor:editor delegate:self start:0 length:_editingCell.stringValue.length];
    }
}

- (void)updateGridArea:(LIGridArea *)anArea withStringValue:(NSString *)aString {
    id objectValue = nil;
    NSFormatter *formatter = self.editingCell.formatter;
    
    if (formatter == nil || [formatter getObjectValue:&objectValue forString:aString errorDescription:NULL] == NO) {
        objectValue = aString;
    }
    
    [self.dataSource gridControl:self setObjectValue:objectValue forArea:self.editingArea];
    [self setNeedsDisplayInRect:[self rectForArea:self.editingArea]];
}

- (BOOL)textShouldBeginEditing:(NSText *)textObject {
    if ([self.delegate respondsToSelector:@selector(control:textShouldBeginEditing:)]) {
        return [self.delegate control:self textShouldBeginEditing:textObject];
    }
    return YES;
}
- (BOOL)textShouldEndEditing:(NSText *)textObject {
    if ([self.delegate respondsToSelector:@selector(control:textShouldEndEditing:)]) {
        return [self.delegate control:self textShouldEndEditing:textObject];
    }
    return YES;
}

- (void)textDidBeginEditing:(NSNotification *)notification {
    NSNotification *note = [NSNotification notificationWithName:NSControlTextDidBeginEditingNotification
                                                         object:self
                                                       userInfo:@{@"NSFieldEditor" : notification.object}];

    [[NSNotificationCenter defaultCenter] postNotification:note];
}

- (void)textDidChange:(NSNotification *)notification {
    NSNotification *note = [NSNotification notificationWithName:NSControlTextDidChangeNotification
                                                         object:self
                                                       userInfo:@{@"NSFieldEditor" : notification.object}];

    [[NSNotificationCenter defaultCenter] postNotification:note];
    
    if (self.editingCell.isContinuous) {
        NSText      *textObj = notification.object;
        NSString    *stringValue = textObj.string.copy;
        
        [self updateGridArea:self.editingArea withStringValue:stringValue];
    }
}

- (void)textDidEndEditing:(NSNotification *)notification {
    NSNotification *note = [NSNotification notificationWithName:NSControlTextDidChangeNotification
                                                         object:self
                                                       userInfo:@{@"NSFieldEditor"  : notification.object,
                                                                  @"NSTextMovement" : notification.userInfo[@"NSTextMovement"]}];
    
    [[NSNotificationCenter defaultCenter] postNotification:note];
    
    NSText      *textObj = notification.object;
    NSString    *stringValue = textObj.string.copy;
    
    [self updateGridArea:self.editingArea withStringValue:stringValue];

    self.editingArea    = nil;
    self.editingCell    = nil;
    
    textObj.delegate    = nil;
    textObj.string      = @"";
    
    [textObj.superview removeFromSuperview];
    
    [self.window makeFirstResponder:self];
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if ([self.delegate respondsToSelector:@selector(control:textView:doCommandBySelector:)]
        && [self.delegate control:self textView:textView doCommandBySelector:commandSelector]) {
        return YES;
    }
    else if (   commandSelector  == @selector(insertTab:)
             || commandSelector  == @selector(insertBacktab:)
             || commandSelector  == @selector(insertNewline:)) {
        
        LIGridArea *previousArea = self.editingArea;
        
        [self.window makeFirstResponder:self];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:commandSelector withObject:self];
#pragma clang diagnostic pop
        
        LIGridArea *nextArea = self.selectedAreas.lastObject;
        
        if (![nextArea isEqual:previousArea]) {
            [self editArea:nextArea];
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Layout

- (NSUInteger)numberOfRows {
    return (_rowSpans.size() - 1) / 2;
}
- (NSUInteger)numberOfColumns {
    return (_columnSpans.size() - 1) / 2;
}

- (NSSize)intrinsicContentSize {
    const GridSpan lastRow = _rowSpans.size() ? _rowSpans.back() : GridSpan();
    const GridSpan lastCol = _columnSpans.size() ? _columnSpans.back() : GridSpan();
    
    return NSMakeSize(lastCol.end(), lastRow.end());
}

- (NSRect)rectForArea:(LIGridArea *)area {
    GridArea gridArea = area;
    return RectWithGridSpanListRanges(gridArea.rowSpanRange, gridArea.columnSpanRange, _rowSpans, _columnSpans);
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

- (BOOL)getRow:(NSUInteger *)rowP column:(NSUInteger *)colP atPoint:(NSPoint)point {
    NSUInteger rowIndex = IndexOfSpanWithLocation(_rowSpans, point.y);
    NSUInteger colIndex = IndexOfSpanWithLocation(_columnSpans, point.x);
    
    if (rowP) *rowP = (rowIndex != NSNotFound && IS_CELL_INDEX(rowIndex)) ? GRID_TO_CELL(rowIndex) : NSNotFound;
    if (colP) *colP = (colIndex != NSNotFound && IS_CELL_INDEX(colIndex)) ? GRID_TO_CELL(colIndex) : NSNotFound;
    
    return ((rowP == NULL || *rowP != NSNotFound) && (colP == NULL || *colP != NSNotFound));
}

- (LIGridArea *)areaAtRow:(NSUInteger)row column:(NSUInteger)column {
    LIGridArea *area = nil;
    
    for (auto it = _fixedAreaMap.begin(); it != _fixedAreaMap.end(); it++) {
        LIGridArea *fixedArea = it->first;
        fixedArea.representedObject = it->second;
        
        if ([fixedArea containsRow:row column:column]) {
            area = fixedArea;
            break;
        }
    }
    if (area == nil) {
        area = [[LIGridArea alloc] initWithRow:row column:column representedObject:nil];
    }
    
    return area;
}

- (NSArray *)fixedAreasInRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    NSMutableArray *fixedAreas = @[].mutableCopy;
    GridArea area = [[LIGridArea alloc] initWithRowRange:rowRange columnRange:columnRange representedObject:nil];
    
    for (auto it = _fixedAreaMap.begin(); it != _fixedAreaMap.end(); it++) {
        if (area.intersects(it->first)) {
            LIGridArea *fixedArea = it->first;
            fixedArea.representedObject = it->second;
            
            [fixedAreas addObject:fixedArea];
        }
    }
    return fixedAreas;
}

#pragma mark -
#pragma mark Animation

- (void)scrollToArea:(LIGridArea *)area animate:(BOOL)shouldAnimate {
    if (shouldAnimate) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setAllowsImplicitAnimation:YES];
            [self scrollRectToVisible:[self rectForArea:area]];
        } completionHandler:^{
        }];
    } else {
        [self scrollRectToVisible:[self rectForArea:area]];
    }
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
                if (_showsSelection) {
                    BOOL isSelected = NO;
                    for (LIGridArea *selectedArea in self.selectedAreas) {
                        GridArea selectedGridArea = selectedArea;
                        if (area.intersects(selectedGridArea)) {
                            isSelected = YES;
                            break;
                        }
                    }
                    [drawingCell setHighlighted:isSelected && ![drawingArea isEqual:self.editingArea]];
                }
                [drawingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:drawingArea]];
                
                id effectiveCell = ((_delegateWillDrawCellForArea) ? [self.delegate gridControl:self willDrawCell:drawingCell forArea:drawingArea] : drawingCell);
                
                [effectiveCell drawWithFrame:rect inView:self];
                [effectiveCell setControlView:nil];
            }
        }
    }
    
    GridArea visibleArea(rowSpanRange, colSpanRange);
    
    for (auto it = _fixedAreaMap.begin(); it != _fixedAreaMap.end(); it++) {
        if (it->first.intersects(visibleArea)) {
            LIGridArea *fixedArea = it->first;
            fixedArea.representedObject = it->second;
            
            NSRect rect = RectWithGridSpanListRanges(it->first.rowSpanRange, it->first.columnSpanRange, _rowSpans, _columnSpans);
            
            if (_showsSelection) {
                BOOL isSelected = NO;
                for (LIGridArea *selectedArea in self.selectedAreas) {
                    GridArea selectedGridArea = selectedArea;
                    if (it->first.intersects(selectedGridArea)) {
                        isSelected = YES;
                        break;
                    }
                }
                [drawingCell setHighlighted:isSelected && ![fixedArea isEqual:self.editingArea]];
            }
            
            [drawingCell setObjectValue:[self.dataSource gridControl:self objectValueForArea:fixedArea]];
            
            id effectiveCell = ((_delegateWillDrawCellForArea) ? [self.delegate gridControl:self willDrawCell:drawingCell forArea:fixedArea] : drawingCell);
            [effectiveCell drawWithFrame:rect inView:self];
            [effectiveCell setControlView:nil];
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
            [((_delegateWillDrawCellForRowDivider) ? [self.delegate gridControl:self willDrawCell:dividerCell forRowDividerAtIndex:r/2] : dividerCell) drawWithFrame:rect inView:nil];
        }
    }
    for (NSUInteger c = IS_DIVIDER_INDEX(colSpanRange.start) ? colSpanRange.start : colSpanRange.start + 1, maxc = colSpanRange.end(); c <= maxc; c += 2) {
        NSRect rect = NSMakeRect(_columnSpans[c].start, NSMinY(dirtyRect), _columnSpans[c].length, NSHeight(dirtyRect));
        
        if (!NSIsEmptyRect(rect)) {
            dividerCell.dividerColor = self.dividerColor;
            [((_delegateWillDrawCellForColumnDivider) ? [self.delegate gridControl:self willDrawCell:dividerCell forColumnDividerAtIndex:c/2] : dividerCell) drawWithFrame:rect inView:nil];
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

