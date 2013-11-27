//
//  LISpreadsheetControl.m
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/20/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LISpreadsheetControl.h"

#import "LIGridField.h"
#import "LIGridControl.h"

@implementation LISpreadsheetControl

+ (Class)cellClass {
    return [LIGridField class];
}

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureSpreadsheetControl];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureSpreadsheetControl];
}

- (void)configureSpreadsheetControl {
    _spreadsheet    = [[LIGridControl alloc] initWithFrame:NSZeroRect];

    _rowHeader      = [[LIGridControl alloc] initWithFrame:NSZeroRect];
    _columnHeader   = [[LIGridControl alloc] initWithFrame:NSZeroRect];
    
    [self setSubviews:@[_spreadsheet, _rowHeader, _columnHeader]];
}

@end
