//
//  LIGridControl.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridControl.h"
#import "LIGridCell.h"

#include <vector>
#include <algorithm>

#define DF_DIVIDER_COLOR    [NSColor gridColor]
#define DF_BACKGROUND_COLOR [NSColor whiteColor]


class LIGridSpan {
public:
    LIGridSpan() : start(0), length(0) {}
    LIGridSpan(CGFloat v) : start(v), length(0) {}
    LIGridSpan(CGFloat s, CGFloat l) : start(s), length(l) {}
    LIGridSpan(const LIGridSpan& c) : start(c.start), length(c.length) {}
    
    bool operator<(const LIGridSpan& other) const {
        return start < other.start;
    }
    
    CGFloat start, length;
    
};

typedef std::vector<LIGridSpan> LIGridSpanList;

static NSUInteger binary_search(const LIGridSpanList& list, CGFloat value, BOOL match_nearest = false) {
    size_t len = list.size();
    
    if (len > 0) {
        if (match_nearest) {
            CGFloat minv = list[0].start;
            CGFloat maxv = list[len-1].start + list[len-1].length;
            
            if (value < minv) {
                return 0;
            } else if (value > maxv) {
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

    LIGridSpanList _rowSpans, _columnSpans;
}

+ (Class)cellClass {
    return [LIGridCell class];
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

- (void)configureGridControl {
    _dividerColor = DF_DIVIDER_COLOR;
    _backgroundColor = DF_BACKGROUND_COLOR;
    
    LIGridCell *cell = [[LIGridCell alloc] initTextCell:@"0.0"];
    [self setCell:cell];
    
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
    
    _rowSpans.resize(rowCount * 2 + 1);
    _columnSpans.resize(columnCount * 2 + 1);
    
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
    
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
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

#define NROWS ((_rowSpans.size() - 1) / 2)
#define NCOLS ((_columnSpans.size() - 1) / 2)

- (NSSize)intrinsicContentSize {
    const LIGridSpan& lastRow = _rowSpans.size() ? _rowSpans.back() : LIGridSpan();
    const LIGridSpan& lastCol = _columnSpans.size() ? _columnSpans.back() : LIGridSpan();
    
    return NSMakeSize(lastCol.start + lastCol.length, lastRow.start + lastRow.length);
}

- (BOOL)getRowSpanRange:(NSRange&)rowSpanRange columnSpanRange:(NSRange&)columnSpanRange inRect:(NSRect)rect {
    NSUInteger rlb = binary_search(_rowSpans, NSMinY(rect), true);
    NSUInteger rub = binary_search(_rowSpans, NSMaxY(rect), true);
    
    NSUInteger clb = binary_search(_columnSpans, NSMinX(rect), true);
    NSUInteger cub = binary_search(_columnSpans, NSMaxX(rect), true);
    
    rowSpanRange.location        = rlb;
    rowSpanRange.length          = rub - rlb;
    
    columnSpanRange.location     = clb;
    columnSpanRange.length       = cub - clb;
    
    return rowSpanRange.location != NSNotFound && columnSpanRange.location != NSNotFound;
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
    NSInteger rectCount;
    const NSRect *rectArray;
    
    [self getRectsBeingDrawn:&rectArray count:&rectCount];
    
    rectArray = &dirtyRect;
    rectCount = 1;
    
    [self drawBackground:rectArray count:rectCount];
    
    if (_rowSpans.size() && _columnSpans.size()) {
        [self drawCells:rectArray count:rectCount];
        [self drawDividers:rectArray count:rectCount];
    }
}

- (void)drawBackground:(const NSRect *)rectArray count:(NSInteger)rectCount {
    [self.backgroundColor set];
    
    NSRectFillList(rectArray, rectCount);
}

- (void)drawDividers:(const NSRect *)rectArray count:(NSInteger)rectCount {
    [self.dividerColor set];
    
    for (NSUInteger i = 0; i < rectCount; i++) {
        NSRect dirtyRect = rectArray[i];
        
        NSRange rowSpanRange, columnSpanRange;
        if ([self getRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange inRect:dirtyRect]) {
            
            BOOL firstIndexIsARow = rowSpanRange.location % 2;
            BOOL firstIndexIsAColumn = columnSpanRange.location % 2;
            
            for (NSUInteger i = (firstIndexIsARow) ? rowSpanRange.location + 1 : rowSpanRange.location;
                 i <= NSMaxRange(rowSpanRange);
                 i += 2) {
                NSRectFill(NSMakeRect(NSMinX(dirtyRect), _rowSpans[i].start, NSWidth(dirtyRect), _rowSpans[i].length));
            }
            
            for (NSUInteger i = (firstIndexIsAColumn) ? columnSpanRange.location + 1 : columnSpanRange.location;
                 i <= NSMaxRange(columnSpanRange);
                 i += 2) {
                NSRectFill(NSMakeRect(_columnSpans[i].start, NSMinY(dirtyRect), _columnSpans[i].length, NSHeight(dirtyRect)));
            }
        }
    }
}
- (void)drawCells:(const NSRect *)rectArray count:(NSInteger)rectCount {
    LIGridCell *drawingCell = [self.cell copy];

    drawingCell.objectValue = @(0.0f);
    
    for (NSUInteger i = 0; i < rectCount; i++) {
        NSRect dirtyRect = rectArray[i];
        
        NSRange rowSpanRange, columnSpanRange;
        if ([self getRowSpanRange:rowSpanRange columnSpanRange:columnSpanRange inRect:dirtyRect]) {
            
            BOOL firstIndexIsARow = rowSpanRange.location % 2;
            BOOL firstIndexIsAColumn = columnSpanRange.location % 2;
            
            for (NSUInteger r = (firstIndexIsARow) ? rowSpanRange.location : rowSpanRange.location + 1;
                 r <= NSMaxRange(rowSpanRange);
                 r += 2) {
                
                for (NSUInteger c = (firstIndexIsAColumn) ? columnSpanRange.location : columnSpanRange.location + 1;
                     c <= NSMaxRange(columnSpanRange);
                     c += 2) {
                    
                    NSRect cellFrame = NSMakeRect(_columnSpans[c].start, _rowSpans[r].start, _columnSpans[c].length, _rowSpans[r].length);
                    
                    [self drawCell:drawingCell withFrame:cellFrame];
                }
            }
        }
    }
}

- (void)drawCell:(LIGridCell *)cell withFrame:(NSRect)frame {
    [cell drawWithFrame:frame inView:self];
}

@end
