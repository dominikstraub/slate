//
//  JSInfoWrapper.h
//  Slate
//
//  Created by Jigish Patel on 1/21/13.
//  Copyright 2013 Jigish Patel. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class ScreenWrapper;
@class AccessibilityWrapper;
@class JSWindowWrapper;
@class JSApplicationWrapper;
@class JSScreenWrapper;

@protocol JSInfoWrapperExports <JSExport>
- (JSWindowWrapper *)window;
- (JSApplicationWrapper *)app;
- (JSScreenWrapper *)screen;
- (void)eachApp:(JSValue *)func;
- (void)eapp:(JSValue *)func;
- (JSWindowWrapper *)windowUnderPoint:(id)point;
- (JSWindowWrapper *)wup:(id)point;
- (BOOL)isRectOffScreen:(id)rect;
- (BOOL)rectoff:(id)rect;
- (BOOL)isPointOffScreen:(id)point;
- (BOOL)pntoff:(id)point;
- (JSScreenWrapper *)screenForRef:(id)ref;
- (JSScreenWrapper *)screenr:(id)ref;
- (NSInteger)screenCount;
- (NSInteger)screenc;
- (JSScreenWrapper *)screenUnderPoint:(id)point;
- (JSScreenWrapper *)sup:(id)point;
- (void)eachScreen:(JSValue *)func;
- (void)escreen:(JSValue *)func;
- (id)jsMethods;
@end

@interface JSInfoWrapper : NSObject <JSInfoWrapperExports> {
  ScreenWrapper *sw;
  AccessibilityWrapper *aw;
}

@property (strong) ScreenWrapper *sw;
@property (strong) AccessibilityWrapper *aw;

- (id)initWithAccessibilityWrapper:(AccessibilityWrapper *)_aw screenWrapper:(ScreenWrapper *)_sw;

+ (JSInfoWrapper *)getInstance;

@end
