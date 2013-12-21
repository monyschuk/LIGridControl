//
//  LIGridArea.h
//  LIGrid
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LIGridArea : NSObject <NSCopying>

#pragma mark -
#pragma mark Lifecycle

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object;
- (id)initWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object; // designated initializer

#pragma mark -
#pragma mark Properties

@property(nonatomic) NSUInteger row, column;
@property(nonatomic) NSRange    rowRange, columnRange;

@property(nonatomic, strong) id representedObject;

#pragma mark -
#pragma mark Derived Properties

@property(readonly, nonatomic) NSUInteger maxRow, maxColumn;

#pragma mark -
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea;

#pragma mark -
#pragma mark Intersection

- (BOOL)intersectsArea:(LIGridArea *)otherArea;
- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea;

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column;
- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end
