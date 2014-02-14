//
//  LITableLayouts.h
//  Matrix
//
//  Created by Mark Onyschuk on 2014-01-31.
//  Copyright (c) 2014 Mark Onyschuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LITable;
@protocol LITableLayouts <NSObject>

@property(nonatomic, weak) LITable *tableView;

- (void)didAttachLayoutToTableView:(LITable *)tableView;
- (void)willDetachLayoutFromTableView:(LITable *)tableView;

@end
