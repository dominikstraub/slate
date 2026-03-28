//
//  JSWindowWrapper.h
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

@class AccessibilityWrapper;
@class ScreenWrapper;
@class JSScreenWrapper;
@class JSApplicationWrapper;

@protocol JSWindowWrapperExports <JSExport>
- (NSString *)title;
- (id)topLeft;
- (id)tl;
- (id)size;
- (id)rect;
- (pid_t)pid;
- (BOOL)focus;
- (BOOL)isMinimizedOrHidden;
- (BOOL)hidden;
- (BOOL)isMovable;
- (BOOL)movable;
- (BOOL)isResizable;
- (BOOL)resizable;
- (BOOL)isMain;
- (BOOL)main;
- (BOOL)move:(id)point;
- (BOOL)resize:(id)size;
- (JSScreenWrapper *)screen;
JSExportAs(doOperation, - (BOOL)doOperation:(id)op options:(id)opts);
JSExportAs(doop, - (BOOL)doop:(id)op options:(id)opts);
- (JSApplicationWrapper *)app;
@end

@interface JSWindowWrapper : NSObject <JSWindowWrapperExports> {
  ScreenWrapper *sw;
  AccessibilityWrapper *aw;
}

@property (strong) ScreenWrapper *sw;
@property (strong) AccessibilityWrapper *aw;

- (id)initWithAccessibilityWrapper:(AccessibilityWrapper *)_aw screenWrapper:(ScreenWrapper *)_sw;

@end
