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

#define IS_SPAN_CELL(x)     ((x%2)>0)
#define IS_SPAN_DIVIDER(x)  ((x%2)==0)

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

// Searches an (ordered) GridSpanList for the span index containing value, using a non-recursive binary search.
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
    
    // intersection
    
    bool intersects(const GridArea& other) const {
        return (NSIntersectionRange(rowSpan, other.rowSpan).length > 0 && NSIntersectionRange(columnSpan, other.columnSpan).length > 0);
    }
    
    // comparsion
    bool operator<(const GridArea& other) const {
        if (rowSpan < other.rowSpan) return true;
        if (other.rowSpan < rowSpan) return false;
        
        if (columnSpan < other.columnSpan) return true;
        if (other.columnSpan < columnSpan) return false;
        
        return false;
    }

    // type (and space) conversion
    GridArea(const LIGridArea* coord) {
        // convert from grid space to span space...
        rowSpan.start = coord.rowRange.location * 2 + 1; rowSpan.length = coord.rowRange.length * 2;
        columnSpan.start = coord.columnRange.location * 2 + 1; columnSpan.length = coord.columnRange.length * 2;
    }
    
    operator LIGridArea*() const {
        // convert from span space to grid space...
        NSRange rowRange = NSMakeRange((rowSpan.start - 1) / 2, rowSpan.length / 2);
        NSRange columnRange = NSMakeRange((columnSpan.start - 1) / 2, columnSpan.length / 2);

        return [LIGridArea areaWithRowRange:rowRange columnRange:columnRange representedObject:nil];
    }
    
    GridSpan rowSpan, columnSpan;
};

typedef std::queue<__strong id> GridObjectQueue;
typedef std::map<GridArea, __strong id> GridAreaMap;

@implementation LIGridControl {
    GridSpanList    _rowSpans, _columnSpans;
    GridAreaMap     _spannedAreaMap, _visibleAreaMap;
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

#define RAT(r)      _rowSpans[2*r+1]
#define CAT(c)      _columnSpans[2*c+1]

#define RECTAT(r,c) NSMakeRect(CAT(c).start,RAT(r).start,CAT(c).length,RAT(r).length)

#define NROWS       _rowSpans.size()/2
#define NCOLS       _columnSpans.size()/2

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
    return RECTAT(row, column);
}
- (NSRect)rectForRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    return NSUnionRect(RECTAT(rowRange.location, columnRange.location), RECTAT(rowRange.location + rowRange.length, columnRange.location + columnRange.length));
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
        return popped;
    }
}
- (LIGridCellView *)createNewReusableCell {
    LIGridCellView *cellView = [[LIGridCellView alloc] initWithFrame:NSZeroRect];
    cellView.backgroundColor = self.backgroundColor;
    return cellView;
}
- (void)enqueueReusableCell:(LIGridCellView *)cell {
    _reusableCellQueue.push(cell);
}

- (LIGridDividerView *)dequeueReusableDivider {
    if (_reusableDividerQueue.empty()) {
        return [self createNewReusableDivider];
    } else {
        LIGridDividerView *popped = _reusableDividerQueue.front();
        _reusableDividerQueue.pop();
        return popped;
    }
}
- (LIGridDividerView *)createNewReusableDivider {
    LIGridDividerView *dividerView = [[LIGridDividerView alloc] initWithFrame:NSZeroRect];
    dividerView.backgroundColor = self.dividerColor;
    return dividerView;
}
- (void)enqueueReusableDivider:(LIGridDividerView *)divider {
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

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self updateSubviewsInRect:[self visibleRect]];
}

- (void)removeAllSubviews {
    if ([[self subviews] count] > 0) {
        [self setSubviews:@[]];
    }
}

- (void)updateSubviewsInRect:(NSRect)dirtyRect {
    NSRange rowSpanRange, columnSpanRange;
    if ([self getRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange inRect:dirtyRect]) {
        [self recycleSubviewsOutsideOfRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange];
        [self updateSubviewsInsideOfRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange];
    }
}

- (void)recycleSubviewsOutsideOfRowSpanRange:(const NSRange&)rowSpanRange columnSpanRange:(const NSRange&)columnSpanRange {
    GridArea visibleArea(rowSpanRange, columnSpanRange);
    
    auto it = _visibleAreaMap.cbegin();
    while (it != _visibleAreaMap.cend()) {
        const GridArea& area = it->first;
        if (! area.intersects(visibleArea)) {
            const id view = it->second;
            
            if ([view isKindOfClass:[LIGridCellView class]]) {
                [self enqueueReusableCell:view];
            } else if ([view isKindOfClass:[LIGridDividerView class]]) {
                [self enqueueReusableDivider:view];
            }
            
            _visibleAreaMap.erase(it++);
        }
        else {
            ++it;
        }
    }
}

- (void)updateSubviewsInsideOfRowSpanRange:(const NSRange&)rowSpanRange columnSpanRange:(const NSRange&)columnSpanRange {
    NSUInteger nrows = _rowSpans.size();
    NSUInteger ncols = _columnSpans.size();
    
    for (NSUInteger i = rowSpanRange.location, maxRange = rowSpanRange.location+rowSpanRange.length;
         i <= maxRange;
         i++) {
        if (IS_SPAN_DIVIDER(i)) {
            GridArea dividerArea(_rowSpans[i], GridSpan(0, ncols));
            GridAreaMap::iterator existing = _visibleAreaMap.find(dividerArea);
            
            if (existing == _visibleAreaMap.end()) {
                LIGridDividerView *dividerView = [self dequeueReusableDivider];
                
                dividerView.frame = NSMakeRect(0, _rowSpans[i].start, _columnSpans[ncols-1].start + _columnSpans[ncols-1].length, _rowSpans[i].length);
                if (dividerView.superview == nil) [self addSubview:dividerView];
                
                _visibleAreaMap[dividerArea] = dividerView;
            }
        }
    }
    
    for (NSUInteger i = columnSpanRange.location, maxRange = columnSpanRange.location+columnSpanRange.length;
         i <= maxRange;
         i++) {
        if (IS_SPAN_DIVIDER(i)) {
            GridArea dividerArea(GridSpan(0, nrows), _columnSpans[i]);
            GridAreaMap::iterator existing = _visibleAreaMap.find(dividerArea);
            
            if (existing == _visibleAreaMap.end()) {
                LIGridDividerView *dividerView = [self dequeueReusableDivider];
                
                dividerView.frame = NSMakeRect(_columnSpans[i].start, 0, _columnSpans[i].length, _rowSpans[nrows-1].start + _rowSpans[nrows-1].length);
                if (dividerView.superview == nil) [self addSubview:dividerView];
                
                _visibleAreaMap[dividerArea] = dividerView;
            }
        }
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

- (BOOL)wantsDefaultClipping {
    return NO;
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}

@end

