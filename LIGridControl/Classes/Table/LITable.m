//
//  LITable.m
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITable.h"

#import "LIGrid.h"
#import "LIShadow.h"
#import "LITableLayout.h"

@implementation LITable

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureTable];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureTable];
}

- (void)configureTable {
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    
    _grid           = [[LIGrid alloc] initWithFrame:NSZeroRect];
    _rowHeader      = [[LIGrid alloc] initWithFrame:NSZeroRect];
    _columnHeader   = [[LIGrid alloc] initWithFrame:NSZeroRect];
    
    _rowShadow      = [[LIShadow alloc] initWithFrame:NSZeroRect];
    _columnShadow   = [[LIShadow alloc] initWithFrame:NSZeroRect];
    
    [_rowShadow setShadowDirection:LIShadowDirection_Right];
    [_columnShadow setShadowDirection:LIShadowDirection_Down];
    
    [self setSubviews:@[_grid, _columnHeader, _columnShadow, _rowHeader, _rowShadow]];
    [self setNeedsLayout:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headerFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_rowHeader];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headerFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_columnHeader];
    
    
    __weak LIGrid *weakGrid = _grid;
    __weak LIGrid *weakRowHeader = _rowHeader;
    __weak LIGrid *weakColumnHeader = _columnHeader;
    
    [_grid setScrollToVisibleBlock:^NSRect(NSRect visibleRect) {
        // FIXME: get real values here...
        CGFloat firstVerticalDividerThickness = 0.5;
        CGFloat firstHorizontalDividerThickness = 0.5;
        
        NSRect visibleRectInRowHeader = [weakRowHeader convertRect:visibleRect fromView:weakGrid];
        NSRect visibleRectInColumnHeader = [weakColumnHeader convertRect:visibleRect fromView:weakGrid];
        
        if (NSMinX(visibleRectInRowHeader) < NSMaxX(weakRowHeader.bounds)) {
            visibleRect = NSOffsetRect(visibleRect, -NSWidth(weakRowHeader.bounds) - firstHorizontalDividerThickness, 0);
        }
        if (NSMinY(visibleRectInColumnHeader) < NSMaxY(weakColumnHeader.bounds)) {
            visibleRect = NSOffsetRect(visibleRect, 0, -NSHeight(weakColumnHeader.bounds) - firstVerticalDividerThickness);
        }
        
        return visibleRect;
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];

    [self setTableLayout:nil];
}

#pragma mark -
#pragma mark Header Float

- (void)headerFrameDidChange:(NSNotification *)notification {
    NSView *header = [notification object];
    
    if (header == _rowHeader) {
        CGFloat width = NSWidth(header.frame);
        CGFloat gridOffset = NSMinX(self.grid.frame);
        
        if (fabs(width-gridOffset) > 0.1) {
            [self invalidateIntrinsicContentSize];
            [self setNeedsLayout:YES];
        }
    } else if (header == _columnHeader) {
        CGFloat height = NSHeight(header.frame);
        CGFloat gridOffset = NSMinY(self.grid.frame);
        if (fabs(height-gridOffset) > 0.1) {
            [self invalidateIntrinsicContentSize];
            [self setNeedsLayout:YES];
        }
    }
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (self.enclosingScrollView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:self.enclosingScrollView.contentView];
    }
}
- (void)viewDidMoveToSuperview {
    if (self.enclosingScrollView) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clipViewBoundsDidChange:)
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:self.enclosingScrollView.contentView];
        
        [self clipViewBoundsDidChange:nil];
    }
}

- (void)clipViewBoundsDidChange:(NSNotification *)notification {
    [_rowShadow setHidden:[self rowHeaderFloatOffset] < 0.1];
    [_columnShadow setHidden:[self columnHeaderFloatOffset] < 0.1];
    
    [self setNeedsLayout:YES];
}

- (CGFloat)rowHeaderFloatOffset {
    return NSMinX(self.visibleRect);
}

- (CGFloat)columnHeaderFloatOffset {
    return NSMinY(self.visibleRect);
}

#pragma mark -
#pragma mark Layout Manager

- (void)setLayoutManager:(LITableLayout *)layoutManager {
    if (_layoutManager != layoutManager) {
        _layoutManager = layoutManager;
        [_layoutManager awakeInTableView:self];
    }
}

- (void)setTableLayout:(id<LITableLayouts>)tableLayout {
    if (_tableLayout != tableLayout) {
        if (_tableLayout) {
            [_tableLayout willDetachLayoutFromTableView:self];
            [_tableLayout setTableView:nil];
        }
        
        _tableLayout = tableLayout;
        
        if (_tableLayout) {
            [_tableLayout setTableView:self];
            [_tableLayout didAttachLayoutToTableView:self];
        }
    }
}


#pragma mark -
#pragma mark Reload

- (void)reloadData {
    [_grid reloadData];
    [_rowHeader reloadData];
    [_columnHeader reloadData];
}

#pragma mark -
#pragma mark Layout

- (void)layout {
    [super layout];
    
    CGFloat gridWidth = NSWidth(self.grid.frame);
    CGFloat gridHeight = NSHeight(self.grid.frame);
    
    CGFloat rowHeaderWidth = NSWidth(self.rowHeader.frame);
    CGFloat colHeaderHeight = NSHeight(self.columnHeader.frame);

    // size to fit contents...
    NSSize oldSize = self.frame.size;
    NSSize newSize = NSMakeSize(gridWidth + rowHeaderWidth, gridHeight + colHeaderHeight);
    
    if (!NSEqualSizes(oldSize, newSize)) {
        [self setFrameSize:NSMakeSize(gridWidth + rowHeaderWidth, gridHeight + colHeaderHeight)];
    }
    
    // reposition table grids...
    NSRect rowFrame, colFrame, gridFrame = self.bounds;

    NSDivideRect(gridFrame, &rowFrame, &gridFrame, rowHeaderWidth,  NSMinXEdge);
    NSDivideRect(gridFrame, &colFrame, &gridFrame, colHeaderHeight, NSMinYEdge);
    
    rowFrame.origin.y = colHeaderHeight; rowFrame.size.height -= colHeaderHeight;
    
    rowFrame = NSOffsetRect(rowFrame, [self rowHeaderFloatOffset], 0);
    colFrame = NSOffsetRect(colFrame, 0, [self columnHeaderFloatOffset]);
    
    self.grid.frame = gridFrame;
    self.rowHeader.frame = rowFrame;
    self.columnHeader.frame = colFrame;
    
    // reposition header shadows...
    NSRect rowShadowFrame, colShadowFrame;
    
    rowShadowFrame = NSOffsetRect(rowFrame, NSWidth(rowFrame), 0); rowShadowFrame.size.width = 10;
    colShadowFrame = NSOffsetRect(colFrame, 0, NSHeight(colFrame)); colShadowFrame.size.height = 10;
    
    self.rowShadow.frame = rowShadowFrame;
    self.columnShadow.frame = colShadowFrame;
}

- (NSSize)intrinsicContentSize {
    CGFloat gridWidth = NSWidth(self.grid.frame);
    CGFloat gridHeight = NSHeight(self.grid.frame);
    
    CGFloat rowHeaderWidth = NSWidth(self.rowHeader.frame);
    CGFloat colHeaderHeight = NSHeight(self.columnHeader.frame);

    return NSMakeSize(gridWidth + rowHeaderWidth, gridHeight + colHeaderHeight);
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return NO;
}
- (BOOL)isFlipped {
    return YES;
}
- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    
}

@end
