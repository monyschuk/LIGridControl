//
//  LIGridControl.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridControl.h"

#import "LIGridArea.h"
#import "LIGridCellView.h"
#import "LIGridDividerView.h"

#include <map>
#include <queue>
#include <vector>
#include <algorithm>

#define DF_DIVIDER_COLOR    [NSColor gridColor]
#define DF_BACKGROUND_COLOR [NSColor whiteColor]

struct GridSpan {
    GridSpan() : start(0), length(0) {}
    GridSpan(CGFloat v) : start(v), length(0) {}
    GridSpan(CGFloat s, CGFloat l) : start(s), length(l) {}
    GridSpan(const GridSpan& other) : start(other.start), length(other.length) {}
    
    // comparison
    bool operator<(const GridSpan& other) const {
        if (start < other.start) return true;
        if (other.start < start) return false;
        
        return false;
    }
    
    // type conversion
    operator NSRange() const { return NSMakeRange(start, length); }
    GridSpan(const NSRange& range) : start(range.location), length(range.length) {}
    
    CGFloat start, length;
};

typedef std::vector<GridSpan> GridSpanList;

static NSUInteger IndexOfSpanWithLocation(const GridSpanList& list, CGFloat value, BOOL match_nearest = false) {
    size_t len = list.size();
    
    if (len > 0) {
        if (match_nearest) {
            CGFloat minv = list[0].start;
            CGFloat maxv = list[len-1].start + list[len-1].length;
            
            if (value <= minv) {
                return 0;
            } else if (value >= maxv) {
                return len-1;
            }
        }
        
        NSInteger imin = 0, imax = len - 1;
        
        while (imax >= imin) {
            NSInteger  imid = (imin + imax) / 2;
            CGFloat    minv = list[imid].start;
            CGFloat    maxv = list[imid].start + list[imid].length;
            
            if (value >= minv && value < maxv) {
                return imid;
            }
            else if (value < minv) {
                imax = imid - 1;
            }
            else {
                imin = imid + 1;
            }
        }
    }
    
    return NSNotFound;
}

struct GridArea {
    GridArea() : rowSpan(GridSpan()), columnSpan(GridSpan()) {}
    GridArea(GridSpan rowSpan, GridSpan colSpan) : rowSpan(rowSpan), columnSpan(colSpan) {}
    GridArea(const GridArea& other) : rowSpan(other.rowSpan), columnSpan(other.columnSpan) {}
    
    // comparsion
    bool operator<(const GridArea& other) const {
        if (rowSpan < other.rowSpan) return true;
        if (other.rowSpan < rowSpan) return false;
        
        if (columnSpan < other.columnSpan) return true;
        if (other.columnSpan < columnSpan) return false;
        
        return false;
    }

    // type conversion
    GridArea(const LIGridArea* coord) {
        
        // convert from coord space to span space...
        rowSpan.start = coord.rowRange.location * 2 + 1; rowSpan.length = coord.rowRange.length * 2;
        columnSpan.start = coord.columnRange.location * 2 + 1; columnSpan.length = coord.columnRange.length * 2;
    }
    
    operator LIGridArea*() const {
        // convert from span space to coord space...
        NSRange rowRange = NSMakeRange((rowSpan.start - 1) / 2, rowSpan.length / 2);
        NSRange columnRange = NSMakeRange((columnSpan.start - 1) / 2, columnSpan.length / 2);

        return [LIGridArea areaWithRowRange:rowRange columnRange:columnRange representedObject:nil];
    }
    
    GridSpan rowSpan, columnSpan;
};

typedef std::queue<__strong id> GridObjectQueue;
typedef std::map<GridArea, __strong id> GridAreaMap;

@implementation LIGridControl {
    // Instance variables rowSpans and columnSpans both store divider and cell areas across each axis.
    // For a given number of rows or columns - lets denote this j - then the size of the vector will be 2j+1,
    // meaning to say that for 5 rows, rowSpans will contain 5 pairs (2j) of divider and row entries, plus an extra
    // divider entry for the trailing divider (+1).
    //
    // When we draw, we'll frequently calculate ranges of indexes in our row and column span lists that lie within a
    // particular rectangle. To determine whether the starting index of a given range represents either a row or column,
    // or a row divider or column divider, we need to divide the index by 2 and check whether we have a remainder.
    // Odd indexes denote cells while even indexes denote dividers.

    GridSpanList _rowSpans, _columnSpans;

    GridAreaMap _spannedAreaMap, _visibleAreaMap;
    GridObjectQueue _reusableCellQueue, _reusableDividerQueue;
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
    if (self.enclosingScrollView) [self stopObservingScrollView:self.enclosingScrollView];
}

- (void)configureGridControl {
    _dividerColor       = DF_DIVIDER_COLOR;
    _backgroundColor    = DF_BACKGROUND_COLOR;
    
    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
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
    NSUInteger spanningCount = [self.dataSource gridControlNumberOfFixedAreas:self];

    _spannedAreaMap.clear();

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
    
    for (i = 0; i < spanningCount; i++) {
        LIGridArea *coord = [self.dataSource gridControl:self fixedAreaAtIndex:i];
        _spannedAreaMap[coord] = coord.representedObject;
    }
    
    [self invalidateIntrinsicContentSize];
    [self updateSubviewsInRect:self.visibleRect];
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
#pragma mark Layout

#define R_AT(x) _rowSpans[2*x+1]
#define C_AT(x) _columnSpans[2*x+1]

#define RC_RECT(r, c) NSMakeRect(C_AT(c).start, R_AT(r).start, C_AT(c).length, R_AT(r).length)

#define NROWS ((_rowSpans.size() - 1) / 2)
#define NCOLS ((_columnSpans.size() - 1) / 2)

- (NSSize)intrinsicContentSize {
    const GridSpan& lastRow = _rowSpans.size() ? _rowSpans.back() : GridSpan();
    const GridSpan& lastCol = _columnSpans.size() ? _columnSpans.back() : GridSpan();
    
    return NSMakeSize(lastCol.start + lastCol.length, lastRow.start + lastRow.length);
}

- (BOOL)getRowSpanRange:(NSRange&)rowSpanRange columnSpanRange:(NSRange&)columnSpanRange inRect:(NSRect)rect {
    NSUInteger rlb = IndexOfSpanWithLocation(_rowSpans, NSMinY(rect), true);
    NSUInteger rub = IndexOfSpanWithLocation(_rowSpans, NSMaxY(rect), true);
    
    NSUInteger clb = IndexOfSpanWithLocation(_columnSpans, NSMinX(rect), true);
    NSUInteger cub = IndexOfSpanWithLocation(_columnSpans, NSMaxX(rect), true);
    
    rowSpanRange.location        = rlb;
    rowSpanRange.length          = rub - rlb;
    
    columnSpanRange.location     = clb;
    columnSpanRange.length       = cub - clb;
    
    return rowSpanRange.location != NSNotFound && columnSpanRange.location != NSNotFound;
}

- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column {
    return RC_RECT(row, column);
}
- (NSRect)rectForRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    return NSUnionRect(RC_RECT(rowRange.location, columnRange.location), RC_RECT(rowRange.location + rowRange.length, columnRange.location + columnRange.length));
}

- (NSRect)rectForRowDividerAtIndex:(NSUInteger)index {
    NSRect rowRect = self.bounds;
    rowRect.origin.y = _rowSpans[index].start;
    rowRect.size.height = _rowSpans[index].length;
    return rowRect;
}
- (NSRect)rectForColumnDividerAtIndex:(NSUInteger)index {
    NSRect columnRect = self.bounds;
    columnRect.origin.x = _columnSpans[index].start;
    columnRect.size.width = _columnSpans[index].length;
    return columnRect;
}

#pragma mark -
#pragma mark Reusable, Visible Views

- (LIGridCellView *)dequeueReusableCell {
    if (_reusableCellQueue.empty()) {
        return [self createNewReusableCell];
    } else {
        LIGridCellView *popped = _reusableCellQueue.front();
        _reusableCellQueue.pop();
        [popped setHidden:NO];
        return popped;
    }
}
- (LIGridCellView *)createNewReusableCell {
    LIGridCellView *cellView = [[LIGridCellView alloc] initWithFrame:NSZeroRect];
    cellView.backgroundColor = self.backgroundColor;
    return cellView;
}
- (void)enqueueReusableCell:(LIGridCellView *)cell {
    [cell setHidden:YES];
    _reusableCellQueue.push(cell);
}

- (LIGridDividerView *)dequeueReusableDivider {
    if (_reusableDividerQueue.empty()) {
        return [self createNewReusableDivider];
    } else {
        LIGridDividerView *popped = _reusableDividerQueue.front();
        _reusableDividerQueue.pop();
        [popped setHidden:NO];
        return popped;
    }
}
- (LIGridDividerView *)createNewReusableDivider {
    LIGridDividerView *dividerView = [[LIGridDividerView alloc] initWithFrame:NSZeroRect];
    dividerView.backgroundColor = self.dividerColor;
    return dividerView;
}
- (void)enqueueReusableDivider:(LIGridDividerView *)divider {
    [divider setHidden:YES];
    _reusableDividerQueue.push(divider);
}

#pragma mark -
#pragma mark Visibilty Management

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    NSScrollView *scrollView = [self enclosingScrollView];
    if (scrollView) [self stopObservingScrollView:scrollView];
}
- (void)viewDidMoveToSuperview {
    NSScrollView *scrollView = [self enclosingScrollView];
    if (scrollView) [self startObservingScrollView:scrollView];
    
    [self visibleRectDidChange:nil];
}

- (void)stopObservingScrollView:(NSScrollView *)scrollView {
    NSClipView *clipView = scrollView.contentView;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self name:NSViewFrameDidChangeNotification object:clipView];
    [notificationCenter removeObserver:self name:NSViewBoundsDidChangeNotification object:clipView];
}
- (void)startObservingScrollView:(NSScrollView *)scrollView {
    NSClipView *clipView = scrollView.contentView;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(visibleRectDidChange:) name:NSViewFrameDidChangeNotification object:clipView];
    [notificationCenter addObserver:self selector:@selector(visibleRectDidChange:) name:NSViewBoundsDidChangeNotification object:clipView];
}

- (void)visibleRectDidChange:(NSNotification *)notification {
    if (_rowSpans.size() == 0 || _columnSpans.size() == 0) {
        [self removeAllSubviews];
    }
    else {
        [self updateSubviewsInRect:[self visibleRect]];
    }
}

- (void)removeAllSubviews {
    if ([[self subviews] count] > 0) {
        [self setSubviews:@[]];
    }
}

- (void)updateSubviewsInRect:(NSRect)dirtyRect {
    NSRange rowSpanRange, columnSpanRange;
    if ([self getRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange inRect:dirtyRect]) {
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

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}

@end

