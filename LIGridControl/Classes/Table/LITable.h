//
//  LITable.h
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LIGrid;

@interface LITable : NSView

@property(readonly, nonatomic, strong) LIGrid *grid, *rowHeader, *columnHeader;

@end
