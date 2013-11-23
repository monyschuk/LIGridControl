//
//  LISpreadsheetControl.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/20/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LIGridControl;

@interface LISpreadsheetControl : NSControl

@property(nonatomic, strong) LIGridControl *spreadsheet, *rowHeader, *columnHeader;

@end
