//
//  LIShadow.h
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIShadowDirection_Up,
    LIShadowDirection_Down,
    LIShadowDirection_Left,
    LIShadowDirection_Right
} LIShadowDirection;

@interface LIShadow : NSView

@property(nonatomic) LIShadowDirection shadowDirection;

@end
