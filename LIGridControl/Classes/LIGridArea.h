//
//  LIGridArea.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/24/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LIGridArea : NSObject <NSCopying>

+ (instancetype)areaWithRow:(NSUInteger)row column:(NSUInteger)column representedObject:(id)object;
+ (instancetype)areaWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object;

- (id)initWithRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange representedObject:(id)object;

@property(nonatomic) NSUInteger row, column;
@property(nonatomic) NSRange rowRange, columnRange;
@property(readonly, nonatomic, weak) NSIndexSet *rowIndexes, *columnIndexes;

@property(nonatomic, strong) id representedObject;

#pragma mark -
#pragma mark Intersection

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column;
- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end