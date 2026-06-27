//
//  WindowSnapshot.m
//  Slate
//
//  Created by Jigish Patel on 2/28/12.
//  Copyright 2012 Jigish Patel. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses

#import "WindowSnapshot.h"
#import "Constants.h"

@implementation WindowSnapshot

@synthesize appName, title, topLeft, size;

- (id)init {
  self = [super init];
  return self;
}

- (id)initWithAppName:(NSString *)theAppName title:(NSString *)theTitle topLeft:(NSPoint)theTopLeft size:(NSSize)theSize {
  self = [self init];
  if (self) {
    [self setAppName:theAppName];
    [self setTitle:theTitle];
    [self setTopLeft:theTopLeft];
    [self setSize:theSize];
  }
  return self;
}

- (NSDictionary *)toDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          appName ? appName : @"", APP_NAME,  // nil would terminate the varargs list early and drop later keys
          title ? title : @"", TITLE,
          [NSNumber numberWithFloat:topLeft.x], X,
          [NSNumber numberWithFloat:topLeft.y], Y,
          [NSNumber numberWithFloat:size.width], WIDTH,
          [NSNumber numberWithFloat:size.height], HEIGHT, nil];
}

// Coerce a dictionary value loaded from disk to a float only when it is actually a
// number/string; a malformed file could otherwise supply an array/dict and crash
// -floatValue with an unrecognized selector.
static float floatFromDictValue(id v) {
  if ([v isKindOfClass:[NSNumber class]] || [v isKindOfClass:[NSString class]]) return [v floatValue];
  return 0.0f;
}

+ (WindowSnapshot *)windowSnapshotFromDictionary:(NSDictionary *)dict {
  id appName = [dict objectForKey:APP_NAME];
  id title = [dict objectForKey:TITLE];
  return [[WindowSnapshot alloc] initWithAppName:([appName isKindOfClass:[NSString class]] ? appName : @"")
                                           title:([title isKindOfClass:[NSString class]] ? title : @"")
                                         topLeft:NSMakePoint(floatFromDictValue([dict objectForKey:X]), floatFromDictValue([dict objectForKey:Y]))
                                            size:NSMakeSize(floatFromDictValue([dict objectForKey:WIDTH]), floatFromDictValue([dict objectForKey:HEIGHT]))];
}


@end
