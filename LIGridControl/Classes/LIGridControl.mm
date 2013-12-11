//
//  LIGridControl.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridControl.h"

#import "LIGridArea.h"
#import "LIGridSelection.h"

#import "LIGridField.h"
#import "LIGridDivider.h"

#define DF_DIVIDER_COLOR    [NSColor gridColor]
#define DF_BACKGROUND_COLOR [NSColor whiteColor]


//
//
// UTILITIES
//
//


#include "grid.h"

using namespace li::grid;

static inline area areaWithGridArea(const LIGridArea* gridArea) {
    interval ri = gridArea.rowRange;
    interval ci = gridArea.columnRange;
    
    return area(ri, ci);
}
static inline LIGridArea *gridAreaWithArea(const area& cellArea) {
    NSRange rr = cellArea.rows;
    NSRange cr = cellArea.cols;
    
    return [[LIGridArea alloc] initWithRowRange:rr columnRange:cr representedObject:nil];
}

//
//
// IMPLEMENTATION
//
//

@interface LIGridControl() {
    grid _grid;
    
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
                    LIGridSelection *selection = selectedAreas.lastObject;
                    
                    [weakSelf editArea:selection.editingArea];
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

    _grid.clear();
    _grid.reserve_rows(rowCount);
    _grid.reserve_cols(columnCount);

    // reload row spans...

    NSUInteger i;
    for (i = 0; i < rowCount; i++) {
        _grid.push_row_divider([self.dataSource gridControl:self heightOfRowDividerAtIndex:i]);
        _grid.push_row([self.dataSource gridControl:self heightOfRowAtIndex:i]);
    }
    _grid.push_row_divider([self.dataSource gridControl:self heightOfRowDividerAtIndex:i]);
    
    // reload column spans...
    
    for (i = 0; i < columnCount; i++) {
        _grid.push_col_divider([self.dataSource gridControl:self widthOfColumnDividerAtIndex:i]);
        _grid.push_col([self.dataSource gridControl:self widthOfColumnAtIndex:i]);
    }
    _grid.push_col_divider([self.dataSource gridControl:self widthOfColumnDividerAtIndex:i]);
    
    // reload spanning areas...
    
    for (i = 0; i < fixedAreaCount; i++) {
        LIGridArea *gridArea = [self.dataSource gridControl:self fixedAreaAtIndex:i];
        
        _grid.push_fixed(areaWithGridArea(gridArea), gridArea.representedObject);
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
        for (LIGridSelection *selection in _selectedAreas) [self setNeedsDisplayInRect:[self rectForArea:selection.gridArea]];

        _selectedAreas = [selectedAreas copy];
        
        // draw new selection...
        for (LIGridSelection *selection in _selectedAreas) [self setNeedsDisplayInRect:[self rectForArea:selection.gridArea]];
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
        
        LIGridSelection *selection      = [[LIGridSelection alloc] initWithRow:row column:col gridControl:self];
        NSMutableArray  *selectedAreas  = [[NSMutableArray alloc] initWithArray:self.selectedAreas];

        [self scrollToArea:selection.gridArea animate:YES];
        
        if ([[selectedAreas valueForKey:@"gridArea"] containsObject:selection.gridArea]) {
            [self editArea:selection.editingArea];
            
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
    LIGridSelection *selection  = self.selectedAreas.lastObject;
    
    if (selection != nil) {
        LIGridSelection *nextSelectedArea = nil;
        NSMutableArray  *newSelectedAreas = [[NSMutableArray alloc] initWithArray:self.selectedAreas];
        
        if (extendSelection) {
            nextSelectedArea = [selection selectionByResizingInDirection:direction];
            
            [newSelectedAreas removeLastObject];
            [newSelectedAreas addObject:nextSelectedArea];
        } else {
            nextSelectedArea = [selection selectionByMovingInDirection:direction];

            [newSelectedAreas removeAllObjects];
            [newSelectedAreas addObject:nextSelectedArea];
        }
        
        self.selectedAreas = newSelectedAreas;
        
        // FIXME: we should have nextSelectedArea suggest the scroll-to area
        [self scrollToArea:nextSelectedArea.gridArea animate:YES];
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
        self.selectedAreas = @[self.selectedAreas.lastObject];
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
        
        LIGridSelection *nextSelection = self.selectedAreas.lastObject;
        
        if (![nextSelection.editingArea isEqual:previousArea]) {
            [self editArea:nextSelection.editingArea];
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Layout

- (NSUInteger)numberOfRows {
    return _grid.get_row_count();
}
- (NSUInteger)numberOfColumns {
    return _grid.get_col_count();
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(_grid.get_width(), _grid.get_height());
}

- (NSRect)rectForArea:(LIGridArea *)area {
    return _grid.get_area_rect(areaWithGridArea(area));
}

- (NSRect)rectForRowDivider:(NSUInteger)row {
    return _grid.get_row_divider_rect(row);
}
- (NSRect)rectForColumnDivider:(NSUInteger)column {
    return _grid.get_col_divider_rect(column);
}

- (BOOL)getRow:(NSUInteger *)rowP column:(NSUInteger *)colP atPoint:(NSPoint)point {
    NSUInteger rowIndex, colIndex;
    
    if (_grid.get_cell_coord(rowIndex, colIndex, point)) {
        if (rowP) *rowP = rowIndex;
        if (colP) *colP = colIndex;
        
        return YES;
    }
    
    return NO;
}

- (LIGridArea *)areaAtRow:(NSUInteger)row column:(NSUInteger)column {
    id   cell_obj;
    area cell_area;
    
    if (_grid.get_cell_area(cell_area, cell_obj, row, column)) {
        LIGridArea *gridArea = gridAreaWithArea(cell_area);
        gridArea.representedObject = cell_obj;
        
        return gridArea;
    }
    
    return nil;
}

- (NSArray *)fixedAreasInRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    NSMutableArray *fixedAreas = @[].mutableCopy;

    std::vector<area> fixed_areas;
    std::vector<__strong id> fixed_objs;

    if (_grid.get_fixed_areas(fixed_areas, fixed_objs, interval(rowRange), interval(columnRange))) {
        
        for (int_t i = 0, maxi = fixed_areas.size(); i < maxi; i++) {
            LIGridArea *gridArea = gridAreaWithArea(fixed_areas[i]);
            gridArea.representedObject = fixed_objs[i];
            
            [fixedAreas addObject:gridArea];
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
    
    _grid.visit_cells(dirtyRect, [&](const area& cell_area, const struct rect& rect, id cell_obj) {
        drawingArea.rowRange = cell_area.rows;
        drawingArea.columnRange = cell_area.cols;
        drawingArea.representedObject = cell_obj;
        
        if (_showsSelection) {
            BOOL isSelected = NO;
            for (LIGridSelection *selection in self.selectedAreas) {
                if ([drawingArea intersectsArea:selection.gridArea]) {
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

    });
}

- (void)drawDividers:(NSRect)dirtyRect {
    LIGridDividerCell *dividerCell = [[LIGridDividerCell alloc] initTextCell:@""];

    _grid.visit_row_dividers(dirtyRect, [&](int_t idx, const struct rect& rect) {
        NSRect dividerRect = rect;
        
        if (!NSIsEmptyRect(dividerRect)) {
            dividerCell.dividerColor = self.dividerColor;
            [((_delegateWillDrawCellForRowDivider) ? [self.delegate gridControl:self willDrawCell:dividerCell forRowDividerAtIndex:idx] : dividerCell) drawWithFrame:dividerRect inView:nil];
        }
    });
    _grid.visit_col_dividers(dirtyRect, [&](int_t idx, const struct rect& rect) {
        NSRect dividerRect = rect;
        
        if (!NSIsEmptyRect(dividerRect)) {
            dividerCell.dividerColor = self.dividerColor;
            [((_delegateWillDrawCellForColumnDivider) ? [self.delegate gridControl:self willDrawCell:dividerCell forColumnDividerAtIndex:idx] : dividerCell) drawWithFrame:dividerRect inView:nil];
        }
    });
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

