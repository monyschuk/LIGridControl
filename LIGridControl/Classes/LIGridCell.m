//
//  LIGridCell.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridCell.h"

@implementation LIGridCell{
    NSRect      _fieldEditorOriginalFrame;
    LIGridCell *_fieldEditorPositioningCell;
    BOOL        _fieldEditorIsBeingPositioned;
}

- (id)initTextCell:(NSString *)aString {
    if ((self = [super initTextCell:aString])) {
        [self configureGridCell];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureGridCell];
}

- (void)configureGridCell {
    self.wraps              = YES;
    self.bezeled            = NO;
    self.bordered           = NO;
    self.focusRingType      = NSFocusRingTypeNone;
    
    self.editable           = YES;
    self.selectable         = YES;
    
    self.alignment          = NSRightTextAlignment;
    
    _vertical               = NO;
    _verticalAlignment      = LIGridCellVerticalAlignment_Center;
    
    self.font               = [NSFont fontWithName:@"HelveticaNeue-Light" size:12];
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LIGridCell *copy = [super copyWithZone:zone];
    
    copy->_vertical = _vertical;
    copy->_verticalAlignment = _verticalAlignment;
    
    return copy;
}

#pragma mark -
#pragma mark Layout

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    
    cellSize.width  = ceilf(cellSize.width);
    cellSize.height = ceilf(cellSize.height);
    
    cellSize.height += 2;
    
    return cellSize;
}
- (NSSize)cellSizeForBounds:(NSRect)aRect {
    NSSize cellSize = [super cellSizeForBounds:aRect];
    
    cellSize.width  = ceilf(cellSize.width);
    cellSize.height = ceilf(cellSize.height);
    
    cellSize.height += 2;
    
    return cellSize;
}

- (NSRect)textFrameWithFrame:(NSRect)aRect {
    NSRect textFrame;
    
    textFrame = aRect;
    textFrame.size.height = MIN(aRect.size.height, [super cellSizeForBounds:aRect].height);
    
    switch (self.verticalAlignment) {
        case LIGridCellVerticalAlignment_Top:
            break;
            
        case LIGridCellVerticalAlignment_Center:
            textFrame.origin.y = floorf(NSMidY(aRect) - NSHeight(textFrame) / 2);
            break;
            
        case LIGridCellVerticalAlignment_Bottom:
            textFrame.origin.y = NSMaxY(aRect) - NSHeight(textFrame);
            break;
    }
    
    return textFrame;
}

#pragma mark -
#pragma mark Editing

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)theEvent {
    
    [super editWithFrame:[self textFrameWithFrame:aRect]
                  inView:controlView
                  editor:textObj
                delegate:anObject
                   event:theEvent];
    
    [self startEditingWithFrame:aRect editor:textObj];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {
    
    [super selectWithFrame:[self textFrameWithFrame:aRect]
                    inView:controlView
                    editor:textObj
                  delegate:anObject
                     start:selStart
                    length:selLength];
    
    [self startEditingWithFrame:aRect editor:textObj];
}

- (void)startEditingWithFrame:(NSRect)aRect editor:(NSText *)textObj {
    
    _fieldEditorOriginalFrame = aRect;
    _fieldEditorPositioningCell = self.copy;
    _fieldEditorPositioningCell.stringValue = @"";
    
    textObj.minSize = [_fieldEditorPositioningCell textFrameWithFrame:_fieldEditorOriginalFrame].size;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fieldEditorFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:textObj];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fieldEditorFrameDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:textObj];
}
- (void)endEditing:(NSText *)textObj {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewFrameDidChangeNotification
                                                  object:textObj];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTextDidChangeNotification
                                                  object:textObj];
    
    _fieldEditorPositioningCell = nil;
    
    [super endEditing:textObj];
}

- (void)fieldEditorFrameDidChange:(NSNotification *)aNotification {
    if (_fieldEditorIsBeingPositioned) return;
    
    NSText *textObj = aNotification.object;
    
    _fieldEditorIsBeingPositioned = YES;
    
    _fieldEditorPositioningCell.stringValue = textObj.string;
    NSRect newTextFrame = [_fieldEditorPositioningCell textFrameWithFrame:_fieldEditorOriginalFrame];
    
    [self.controlView setNeedsDisplayInRect:textObj.superview.frame];
    [textObj.superview setFrame:newTextFrame];
    [self.controlView setNeedsDisplayInRect:textObj.superview.frame];
    
    _fieldEditorIsBeingPositioned = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (self.backgroundColor) {
        [self.backgroundColor set];
        NSRectFill(cellFrame);
    }
    if (self.isHighlighted) {
        [[self highlightColorWithFrame:cellFrame inView:controlView] set];
        NSRectFill(cellFrame);
    }
    
    if (self.vertical) {
        [NSGraphicsContext saveGraphicsState];
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        [transform translateXBy:NSMidX(cellFrame) yBy:NSMidY(cellFrame)];
        [transform rotateByDegrees:-90];
        [transform translateXBy:-NSMidX(cellFrame) yBy:-NSMidY(cellFrame)];
        [transform concat];
    }
    
    [super drawWithFrame:[self textFrameWithFrame:cellFrame] inView:controlView];
    
    if (self.vertical) {
        NSFrameRect([self textFrameWithFrame:cellFrame]);
        [NSGraphicsContext restoreGraphicsState];
    }
    
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSColor *color = [super highlightColorWithFrame:cellFrame inView:controlView];
    
    if ([color isEqual:[NSColor secondarySelectedControlColor]]) {
        return [color blendedColorWithFraction:0.66 ofColor:[NSColor whiteColor]];
    }
    else {
        return color;
    }
}


@end
