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

@implementation LITable {
    NSArray *_constraints;
}

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
    
    [_rowShadow addConstraint:
     [NSLayoutConstraint constraintWithItem:_rowShadow attribute:NSLayoutAttributeWidth
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:4]];
    
    [_columnShadow addConstraint:
     [NSLayoutConstraint constraintWithItem:_columnShadow attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:4]];

    [self setSubviews:@[_grid, _columnHeader, _columnShadow, _rowHeader, _rowShadow]];
    [self setNeedsUpdateConstraints:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headerFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_rowHeader];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headerFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_columnHeader];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

#pragma mark -
#pragma mark Header Float

- (void)headerFrameDidChange:(NSNotification *)notification {
    NSView *header = [notification object];
    
    if (header == _rowHeader) {
        CGFloat width = NSWidth(header.frame);
        CGFloat gridOffset = NSMinX(self.grid.frame);
        
        if (fabs(width-gridOffset) > 0.1) {
            [self setNeedsUpdateConstraints:YES];
        }
    } else if (header == _columnHeader) {
        CGFloat height = NSHeight(header.frame);
        CGFloat gridOffset = NSMinY(self.grid.frame);
        if (fabs(height-gridOffset) > 0.1) {
            [self setNeedsUpdateConstraints:YES];
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
    
    [self setNeedsUpdateConstraints:YES];
}

- (CGFloat)rowHeaderFloatOffset {
    NSClipView *clipView = self.enclosingScrollView.contentView;
    
    NSRect clipBounds = [clipView bounds];
    NSRect tableBounds = [clipView convertRect:[self bounds] fromView:self];
    NSRect headerBounds = [clipView convertRect:[self.rowHeader bounds] fromView:self.rowHeader];
    
    if (NSMinX(tableBounds) < NSMinX(clipBounds)
        && (NSMaxX(tableBounds) - NSMinX(clipBounds)) > NSWidth(headerBounds)) {
        return NSMinX(clipBounds) - NSMinX(tableBounds);
    }
    
    return 0;
}

- (CGFloat)columnHeaderFloatOffset {
    NSClipView *clipView = self.enclosingScrollView.contentView;

    NSRect clipBounds = [clipView bounds];
    NSRect tableBounds = [clipView convertRect:[self bounds] fromView:self];
    NSRect headerBounds = [clipView convertRect:[self.columnHeader bounds] fromView:self.rowHeader];
    
    if (NSMinY(tableBounds) < NSMinY(clipBounds)
        && (NSMaxY(tableBounds) - NSMinY(clipBounds)) > NSHeight(headerBounds)) {
        return NSMinY(clipBounds) - NSMinY(tableBounds);
    }

    return 0;
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
        if (_tableLayout) [_tableLayout willDetachLayoutToTableView:self];
        _tableLayout = tableLayout;
        if (_tableLayout) [_tableLayout didAttachLayoutToTableView:self];
    }
}

#pragma mark -
#pragma mark Layout

- (void)updateConstraints {
    [super updateConstraints];
    
    NSMutableArray  *constraints  = @[].mutableCopy;
    NSDictionary    *subviews     = NSDictionaryOfVariableBindings(_grid, _rowHeader, _columnHeader, _rowShadow, _columnShadow);
    
    NSDictionary    *metrics      = @{@"top":       @(NSHeight(self.columnHeader.frame)),
                                      @"left":      @(NSWidth(self.rowHeader.frame)),
                                      @"topFloat":  @([self columnHeaderFloatOffset]),
                                      @"leftFloat": @([self rowHeaderFloatOffset])};
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[_grid]|"
                                             options:0
                                             metrics:metrics
                                               views:subviews]];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[_grid]|"
                                             options:0
                                             metrics:metrics
                                               views:subviews]];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(leftFloat)-[_rowHeader]"
                                             options:0
                                             metrics:metrics
                                               views:subviews]];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topFloat)-[_columnHeader]"
                                             options:0
                                             metrics:metrics
                                               views:subviews]];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_rowHeader][_rowShadow]"
                                             options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom
                                             metrics:metrics
                                               views:subviews]];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_columnHeader][_columnShadow]"
                                             options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
                                             metrics:metrics
                                               views:subviews]];

    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_rowHeader attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_grid attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0]];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_columnHeader attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_grid attribute:NSLayoutAttributeLeft
                                 multiplier:1 constant:0]];
    
    // replace constraints
    [self removeConstraints:_constraints ? _constraints : @[]];
    [self addConstraints:constraints];
    _constraints = constraints;
}

#pragma mark -
#pragma mark Responsive Scrolling

- (void)prepareContentInRect:(NSRect)rect {
    if ([self needsUpdateConstraints]) {
        [self updateConstraintsForSubtreeIfNeeded];
    }
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
