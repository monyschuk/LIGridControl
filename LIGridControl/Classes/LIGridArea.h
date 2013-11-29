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
#pragma mark Union

- (LIGridArea *)unionArea:(LIGridArea *)otherArea;

#pragma mark -
#pragma mark Intersection

- (LIGridArea *)intersectionArea:(LIGridArea *)otherArea;

- (BOOL)containsRow:(NSUInteger)row column:(NSUInteger)column;
- (BOOL)intersectsRowRange:(NSRange)rowRange columnRange:(NSRange)columnRange;

#pragma mark -
#pragma mark Equality

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end

typedef enum {
    LIDirection_Up,
    LIDirection_Down,
    LIDirection_Left,
    LIDirection_Right
} LIDirection;

@class LIGridControl;
@interface LISelectionArea : LIGridArea

- (id)initWithPoint:(NSPoint)point control:(LIGridControl *)gridControl;
- (id)initWithGridArea:(LIGridArea *)gridArea control:(LIGridControl *)gridControl;

@property(readonly, nonatomic) NSPoint              point;
@property(readonly, nonatomic, strong) LIGridArea   *gridArea;
@property(readonly, nonatomic, weak) LIGridControl  *gridControl;

- (LISelectionArea *)areaByAdvancingInDirection:(LIDirection)direction;

@end