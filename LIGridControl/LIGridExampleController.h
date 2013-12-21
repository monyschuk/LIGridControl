//
//  LIGridExampleController.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 2013-12-21.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGrid.h"

@interface LIGridExampleController : NSObject <LIGridDataSource, LIGridDelegate>

@property(nonatomic, weak) IBOutlet LIGrid *gridControl;
@property(nonatomic, strong) NSMutableDictionary  *gridValues;

@end
