//
//  LIGridArea.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"
#import "LIGridControl.h"

@implementation LIGridArea

+ (instancetype)areaWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object {
    return [[self alloc] initWithRowRange:NSMakeRange(row, 1) columnRange:NSMakeRange(column, 1) representedObject:object];
}

+ (instancetype)areaWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object {
    return [[self alloc] initWithRowRange:rowRange columnRange:columnRange representedObject:object];
}

- (id)initWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)representedObject {
    if ((self = [super init])) {
        _rowRange           = rowRange;
        _columnRange        = columnRange;
        _representedObject  = representedObject;
    }
    return self;
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[LIGridArea alloc] initWithRowRange:_rowRange columnRange:_columnRange representedObject:_representedObject];
}

#pragma mark -
#pragma mark Derived Properties

- (NSUInteger)row {
    return _rowRange.location;
}
- (NSUInteger)column {
    return _columnRange.location;
}

- (void)setRow:(NSUInteger)row {
    _rowRange = NSMakeRange(row, 1);
}
- (void)setColumn:(NSUInteger)column {
    _columnRange = NSMakeRange(column, 1);
}

- (NSIndexSet *)rowIndexes {
    return [[NSIndexSet alloc] initWithIndexesInRange:_rowRange];
}
- (NSIndexSet *)columnIndexes {
    return [[NSIndexSet alloc] initWithIndexesInRange:_columnRange];
}

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea {
    return [LIGridArea areaWithRowRange:NSUnionRange(_rowRange, otherArea.rowRange) columnRange:NSUnionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

#pragma mark -
#pragma mark Intersection

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea {
    return [LIGridArea areaWithRowRange:NSIntersectionRange(_rowRange, otherArea.rowRange) columnRange:NSIntersectionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column {
    return NSLocationInRange(row, _rowRange) && NSLocationInRange(column, _columnRange);
}

- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange {
    return NSIntersectionRange(_rowRange, rowRange).length && NSIntersectionRange(_columnRange, columnRange).length;
}

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash {
    NSUInteger val;
    
    val  = _rowRange.location;      val <<= 11;
    val ^= _rowRange.length;        val <<= 11;
    val ^= _columnRange.location;   val <<= 10;
    val ^= _columnRange.length;
    
    return val;
}

- (BOOL)isEqual:(id)object {
    LIGridArea *other = object;
    return other != nil && NSEqualRanges(_rowRange, other->_rowRange) && NSEqualRanges(_columnRange, other->_columnRange);
}


#pragma mark -
#pragma mark Description

- (NSString *)description {
    id rr = (_rowRange.length == 1) ? @(_rowRange.location) : NSStringFromRange(_rowRange);
    id cr = (_columnRange.length == 1) ? @(_columnRange.location) : NSStringFromRange(_columnRange);
    
    return [NSString stringWithFormat:@"(r: %@, c: %@): ro = %@", rr, cr, _representedObject];
}

@end


@implementation LISelectionArea

- (id)initWithPoint:(NSPoint)point control:(LIGridControl *)gridControl {
    if ((self = [self initWithGridArea:[gridControl areaAtPoint:point] control:gridControl])) {
        _point = point;
    }
    return self;
}

- (id)initWithGridArea:(LIGridArea *)gridArea control:(LIGridControl *)gridControl {
    if ((self = [super initWithRowRange:gridArea.rowRange columnRange:gridArea.columnRange representedObject:nil])) {
        _gridArea = gridArea;
        _gridControl = gridControl;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LISelectionArea *copy = [super copyWithZone:zone];
    
    copy->_point = _point;
    copy->_gridArea = _gridArea;
    copy->_gridControl = _gridControl;

    return copy;
}

- (LISelectionArea *)areaByUpdatingSecondPoint:(NSPoint)point {
    return self.copy;
}
- (LISelectionArea *)areaByAdvancingInDirection:(LIDirection)direction {
    return self.copy;
}

@end
