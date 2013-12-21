//
//  LITableExampleController.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 2013-12-21.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGrid.h"

@class LITable;
@interface LITableExampleController : NSObject <LIGridDataSource, LIGridDelegate>

@property(nonatomic, strong) LITable *table;

@property(nonatomic, weak) IBOutlet NSScrollView *scrollView;

@end
