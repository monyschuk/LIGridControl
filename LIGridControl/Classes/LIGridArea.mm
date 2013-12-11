//
//  LIGridArea.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridArea.h"
#import "LIGridControl.h"

#include "grid.h"

using namespace li::grid;

@implementation LIGridArea

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object {
    return [self initWithRowRange:NSMakeRange(row, 0) columnRange:NSMakeRange(column, 0) representedObject:object];
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
    return [[[self class] alloc] initWithRowRange:_rowRange columnRange:_columnRange representedObject:_representedObject];
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
    _rowRange = NSMakeRange(row, 0);
}
- (void)setColumn:(NSUInteger)column {
    _columnRange = NSMakeRange(column, 0);
}

- (NSUInteger)maxRow {
    return NSMaxRange(_rowRange);
}
- (NSUInteger)maxColumn {
    return NSMaxRange(_columnRange);
}

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea {
    if (otherArea == nil) return self;

    return [[LIGridArea alloc] initWithRowRange:NSUnionRange(_rowRange, otherArea.rowRange) columnRange:NSUnionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

#pragma mark -
#pragma mark Intersection

static BOOL rangeIntersectsRange(NSRange range, NSRange otherRange) {
    struct interval r1 = range;
    struct interval r2 = otherRange;
    
    return r1.intersects(r2);
}
- (BOOL)intersectsArea:(LIGridArea *)otherArea {
    if (otherArea == nil) return NO;
    
    return rangeIntersectsRange(_rowRange, otherArea->_rowRange) && rangeIntersectsRange(_columnRange, otherArea->_columnRange);
}

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea {
    if (otherArea == nil) return self;

    return [[LIGridArea alloc] initWithRowRange:NSIntersectionRange(_rowRange, otherArea.rowRange) columnRange:NSIntersectionRange(_columnRange, otherArea.columnRange) representedObject:nil];
}

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column {
    struct interval rr = _rowRange;
    struct interval cr = _columnRange;
    
    return rr.contains(row) && cr.contains(column);
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
    id rr = (_rowRange.length == 0) ? @(_rowRange.location) : NSStringFromRange(_rowRange);
    id cr = (_columnRange.length == 0) ? @(_columnRange.location) : NSStringFromRange(_columnRange);
    
    return [NSString stringWithFormat:@"%@ (r: %@, c: %@): ro = %@", NSStringFromClass([self class]), rr, cr, _representedObject];
}

@end
